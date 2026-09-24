"""Hermes image_generate provider for the laptop ComfyUI API."""

import json
import os
import secrets
import time
import urllib.parse
import urllib.request
from pathlib import Path

from agent.image_gen_provider import (
    DEFAULT_ASPECT_RATIO,
    ImageGenProvider,
    error_response,
    resolve_aspect_ratio,
    success_response,
)


class ComfyUIProvider(ImageGenProvider):
    @property
    def name(self):
        return "comfyui-local"

    def default_model(self):
        return "sd_xl_base_1.0.safetensors"

    def is_available(self):
        return bool(os.environ.get("COMFYUI_URL"))

    def generate(self, prompt, aspect_ratio=DEFAULT_ASPECT_RATIO, *, image_url=None,
                 reference_image_urls=None, **kwargs):
        aspect_ratio = resolve_aspect_ratio(aspect_ratio)
        model = self.default_model()
        if not prompt or not prompt.strip() or image_url or reference_image_urls:
            return error_response(
                error="A text prompt is required; this ComfyUI workflow does not support image editing",
                error_type="invalid_input", provider=self.name, model=model,
                prompt=prompt, aspect_ratio=aspect_ratio,
            )

        base_url = os.environ["COMFYUI_URL"].rstrip("/")

        def request(path, payload=None, timeout=15):
            data = json.dumps(payload).encode() if payload is not None else None
            req = urllib.request.Request(
                base_url + path, data=data,
                headers={"Content-Type": "application/json"} if data else {},
            )
            with urllib.request.urlopen(req, timeout=timeout) as response:
                return response.read()

        try:
            workflow = json.loads(Path("/opt/data/comfyui-workflow.json").read_text())
            workflow["6"]["inputs"]["text"] = prompt.strip()
            workflow["3"]["inputs"]["seed"] = secrets.randbelow(2**53)
            width, height = {
                "landscape": (1024, 640),
                "portrait": (640, 1024),
                "square": (768, 768),
            }[aspect_ratio]
            workflow["5"]["inputs"].update(width=width, height=height)
            workflow["9"]["inputs"]["filename_prefix"] = "Hermes"
            prompt_id = json.loads(request("/prompt", {"prompt": workflow}))["prompt_id"]
            deadline = time.monotonic() + 600
            while time.monotonic() < deadline:
                history = json.loads(request("/history/" + urllib.parse.quote(prompt_id)))
                if prompt_id in history:
                    entry = history[prompt_id]
                    if entry.get("status", {}).get("status_str") == "error":
                        raise RuntimeError("ComfyUI reported a workflow error")
                    images = entry.get("outputs", {}).get("9", {}).get("images", [])
                    if not images:
                        raise RuntimeError("ComfyUI returned no saved image")
                    params = urllib.parse.urlencode({
                        "filename": images[0]["filename"],
                        "subfolder": images[0].get("subfolder", ""),
                        "type": images[0].get("type", "output"),
                    })
                    image = request("/view?" + params, timeout=60)
                    cache = Path(os.environ.get("HERMES_HOME", "/opt/data")) / "cache/images"
                    cache.mkdir(parents=True, exist_ok=True)
                    output = cache / f"comfyui-{prompt_id}.png"
                    output.write_bytes(image)
                    return success_response(
                        image=str(output), model=model, prompt=prompt,
                        aspect_ratio=aspect_ratio, provider=self.name,
                    )
                time.sleep(2)
            raise TimeoutError("ComfyUI did not finish within 10 minutes")
        except Exception as exc:
            return error_response(
                error=str(exc), error_type=type(exc).__name__, provider=self.name,
                model=model, prompt=prompt, aspect_ratio=aspect_ratio,
            )


def register(ctx):
    ctx.register_image_gen_provider(ComfyUIProvider())
