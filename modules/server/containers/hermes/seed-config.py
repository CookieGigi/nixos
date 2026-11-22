"""Apply managed Hermes tool settings without replacing unrelated persisted config."""

import pathlib
import sys

import yaml


path = pathlib.Path(sys.argv[1])
config = yaml.safe_load(path.read_text()) or {}
model = config.setdefault("model", {})
if model.get("default") == "Qwen3.5-4B-Q6_K":
    model["default"] = "Ornith-1.5-9B-Q5_K_M"
config.setdefault("web", {}).update(search_backend="searxng", keyless_fallback=False)
# The laptop ComfyUI service is gone; drop its stale entries if present.
image_gen = config.get("image_gen", {})
if image_gen.get("provider") == "comfyui-local":
    del config["image_gen"]
plugins = config.get("plugins", {})
enabled = plugins.get("enabled", [])
if "comfyui-local" in enabled:
    enabled.remove("comfyui-local")

updated = yaml.safe_dump(config, sort_keys=False)
if updated != path.read_text():
    path.write_text(updated)
