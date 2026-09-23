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
config.setdefault("image_gen", {})["provider"] = "comfyui-local"
plugins = config.setdefault("plugins", {})
enabled = plugins.setdefault("enabled", [])
if "comfyui-local" not in enabled:
    enabled.append("comfyui-local")
if "comfyui-local" in plugins.get("disabled", []):
    plugins["disabled"].remove("comfyui-local")

updated = yaml.safe_dump(config, sort_keys=False)
if updated != path.read_text():
    path.write_text(updated)
