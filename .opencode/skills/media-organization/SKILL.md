---
name: media-organization
description: How to organize the /media HDD folder by content type on the server
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  domain: system-administration
---

## What I do
- Explain the purpose and layout of `/media/` on the server
- Document the convention of organizing by content type (photos, videos, AI, backups, downloads)
- Clarify which content lives on HDD vs NVMe
- Guide adding new top-level directories for new media types

## When to use me
Use this skill when the user asks about:
- Where to store photos, videos, or other media
- How `/media/` is organized
- Adding a new content type or external library to Immich
- Whether something should go on HDD or NVMe

## Hardware context
- **HDD** (`/dev/sda`, LUKS `medialuks`, BTRFS `@media`) — bulk storage, mounted at `/media`
- **NVMe** (`/dev/nvme0n1`, LUKS `cookieluks`, BTRFS `@persist`) — fast storage for databases, thumbnails, processed media

## /media layout conventions

Organize by **content type**, not by application. Each top-level directory is a category:

| Directory | Content | Managed by | Notes |
|-----------|---------|------------|-------|
| `/media/ai/` | AI model weights (GGUF, mmproj) | `llama-container.nix` | Read-only mounts into llama.cpp container |
| `/media/ai/llama-models` | LLM weights | `llama-model-download-all` | Downloaded from HuggingFace |
| `/media/ai/llama-mmproj` | Vision projector weights | `llama-model-download-all` | Paired with multimodal models |
| `/media/pictures/` | Original photos | Immich external library | Read-only mount into immich-server |
| `/media/videos/` | Original videos | Immich external library | Read-only mount into immich-server |
| `/media/backup/` | System backups | Manual or scheduled | BTRFS subvolume `@backup` |
| `/media/downloads/` | Transient downloads | Manual | BTRFS subvolume `@downloads` |

## Rules
1. **Photos and videos are separate** — do not mix them. Immich handles them as distinct external libraries.
2. **Do not put app-generated data here** — thumbnails, encoded video, search indices, and databases belong on NVMe (`/persist/`).
3. **Read-only from containers** — containers mount `/media/*` as `:ro`. If you need write access (e.g., Immich deleting originals), change the mount flag in the Quadlet container definition.
4. **New content type = new top-level directory** — e.g., `/media/music/`, `/media/documents/`, `/media/datasets/`. Update `systemd.tmpfiles.rules` in the relevant Nix module to ensure the directory exists.

## Adding a new external library to Immich
1. Add a tmpfiles rule in `modules/server/immich.nix`:
   ```nix
   "d /media/music 0755 root root -"
   ```
2. Add a container volume mount:
   ```nix
   Volume=/media/music:/media/music:ro
   ```
3. Rebuild (`make server-switch`)
4. In Immich admin UI, create an external library pointing to `/media/music`

## Immich data flow
- **Originals** (HDD): `/media/pictures/`, `/media/videos/`
- **Working set** (NVMe): `/persist/immich/library/` — thumbnails, encoded video, faces, internal uploads
- **Database** (NVMe): `/persist/immich/postgres/`
- **ML cache** (NVMe): `/persist/immich/model-cache/`
