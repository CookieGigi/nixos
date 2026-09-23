# CPU-only image generation

The server runs ComfyUI at `https://comfyui.cookiegigi.com`, restricted to
LAN/VPN clients and protected by Authelia. It uses the CPU-only
`yanwk/comfyui-boot:cpu` container without NVIDIA device access, so llama.cpp
can continue using the GPU. The service is limited to 4 CPU cores and 9 GiB of
RAM; if memory is tight, stop it with `sudo systemctl stop comfyui.service`.

The Stable Diffusion 1.5 checkpoint is downloaded automatically to
`/media/ai/comfyui-checkpoints/v1-5-pruned-emaonly.safetensors`. ComfyUI state,
uploaded images, and generated output persist in `/persist/comfyui/ComfyUI/`.
The first start downloads about 4.3 GB. Start with a 512x512 text-to-image
workflow; use the image-to-image or inpainting workflow with an input image and
mask to edit images. CPU generation can take minutes per image.

The model download must finish before ComfyUI starts. Check its progress with
`journalctl -u comfyui-model-download.service -f` and the container logs with
`journalctl -u comfyui.service -f`. Model and service declarations are in
`modules/server/containers/comfyui/`.

## Open WebUI

Open WebUI connects directly to `http://comfyui:8188` over the private Podman
network, not through Caddy/Authelia. Its SD1.5 text-to-image workflow and node
mappings are declared in `modules/server/containers/open-webui/`; the checkpoint,
512x512 size, and 20 sampling steps are defaults. With
`ENABLE_PERSISTENT_CONFIG=False`, changes made in the Open WebUI admin Images
page are not retained after a restart; edit the Nix configuration instead.

After rebuilding the server, open a chat in Open WebUI, enable **Image** in the
message input's **Integrations** menu, and ask for an image. Generation can take
minutes on CPU. If the option is missing, check the model's Image Generation
capability and your role's image generation permission. For failures, inspect
`journalctl -u open-webui.service -f` and `journalctl -u comfyui.service -f`.
Open WebUI image editing remains disabled: it requires a separate ComfyUI
workflow with an input-image node.
