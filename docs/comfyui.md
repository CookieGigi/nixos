# Laptop GPU image generation

ComfyUI runs on the `xps` laptop's RTX 4070 (8 GiB VRAM), not on the server.
The server's CPU-only SD 1.5 service exceeded its 6 GiB limit and is no longer
declared. The server's GPU remains available to llama.cpp. Image generation is
unavailable whenever the laptop is offline or asleep.

The laptop downloads the SDXL base checkpoint to
`/persist/comfyui/models/checkpoints/sd_xl_base_1.0.safetensors` on first start
(about 6.9 GB). Inputs, outputs, model files and Podman images persist across
reboots under `/persist`. Inspect startup with
`journalctl -u comfyui-model-download.service -f` and
`journalctl -u comfyui.service -f`. Use a batch size of 1; larger workflows may
offload to laptop RAM when the 8 GiB GPU fills up.

The laptop currently uses DHCP address `192.168.1.14`. Reserve this address for
the laptop in the router before deploying the server config. If it changes,
update the upstream in `modules/server/containers/caddy/containers.nix` and the
URLs in `modules/server/containers/{open-webui,hermes}/container.nix`. The
laptop firewall permits the unauthenticated ComfyUI API on port 8188 only from
the server at `192.168.1.49`. Do not expose port 8188 to the internet.

The user-facing `https://comfyui.cookiegigi.com` stays on the server's Caddy
proxy with LAN/VPN access and Authelia. Open WebUI and Hermes contact the laptop
directly from their server containers; their shared SDXL workflow is declared
in `modules/server/containers/open-webui/comfyui-workflow.nix`. Open WebUI uses
768x768 and 25 steps by default. With `ENABLE_PERSISTENT_CONFIG=False`, changes
made in its admin Images page are not retained after restart; edit the Nix
configuration instead. Hermes supports text-to-image, not editing.

For connectivity, check the laptop's `comfyui.service` and try reaching
`http://192.168.1.14:8188/system_stats` from the server. Inspect
`journalctl -u open-webui.service -f` and `journalctl -u hermes.service -f`
for client errors. The old server checkpoint and output data remain on disk;
the NixOS changes do not delete them.
