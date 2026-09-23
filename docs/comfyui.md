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
