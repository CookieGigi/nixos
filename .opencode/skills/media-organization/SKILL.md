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
| `/media/pictures/` | Original photos | Immich external library | Read-only mount into immich-server |
| `/media/videos/` | Original videos | Immich external library | Read-only mount into immich-server |
| `/media/videos/home/` | Home videos | Manual | Subdirectory of videos |
| `/media/videos/movies/` | Movies | Jellyfin (future) | Subdirectory of videos |
| `/media/videos/shows/` | TV shows | Jellyfin (future) | Subdirectory of videos |
| `/media/videos/clips/` | Short clips | Manual | Subdirectory of videos |
| `/media/videos/music-videos/` | Music videos | Manual | Subdirectory of videos |
| `/media/music/` | Music files | Future service | Shared media group |
| `/media/documents/` | Documents | Manual | Subdirectory organization |
| `/media/documents/books/` | E-books | Manual | Subdirectory of documents |
| `/media/documents/papers/` | Academic papers | Manual | Subdirectory of documents |
| `/media/documents/receipts/` | Scanned receipts | Manual | Subdirectory of documents |
| `/media/ai/` | AI model weights | `llama` container | Restricted `ai` group |
| `/media/ai/llama-models` | LLM weights (GGUF) | `llama-model-download-all` | Downloaded from HuggingFace |
| `/media/ai/llama-mmproj` | Vision projector weights | `llama-model-download-all` | Paired with multimodal models |
| `/media/backup/` | System backups | Manual or scheduled | BTRFS subvolume `@backup` |
| `/media/downloads/` | Transient downloads | Manual | BTRFS subvolume `@downloads` |

## Permissions

All `/media/*` directories use `2775 root:media` unless noted:
- `2775` = setgid + rwxrwxr-x
- New files inherit the `media` group automatically
- Both `cookiegigi` and `immich` can read via the `media` group

Exception — `/media/ai/*` uses `2770 root:ai` for restricted AI model access.

## Rules
1. **Photos and videos are separate** — do not mix them. Immich handles them as distinct external libraries.
2. **Do not put app-generated data here** — thumbnails, encoded video, search indices, and databases belong on NVMe (`/persist/`).
3. **Read-only from containers by default** — containers mount `/media/*` as `:ro`. If you need write access (e.g., Immich deleting originals), change the mount flag in the Quadlet container definition.
4. **New content type = new top-level directory** — e.g., `/media/datasets/`, `/media/audiobooks/`. Update `systemd.tmpfiles.rules` in `modules/server/storage-layout.nix`.

## Adding a new top-level directory

1. Add a tmpfiles rule in `modules/server/storage-layout.nix`:
   ```nix
   "d /media/datasets 2775 root media -"
   ```
2. If a container needs access, add a volume mount in the service's `container.nix`:
   ```nix
   Volume=/media/datasets:/media/datasets:ro
   ```
3. Run `nix fmt` and rebuild (`make server-switch`)
4. If using Immich, create an external library in the admin UI

## Adding a new external library to Immich

1. Ensure the directory exists in `/media/` (via tmpfiles rule)
2. Verify the immich container user has access via the `media` group
3. Add a container volume mount in `modules/server/containers/immich/containers.nix`:
   ```nix
   Volume=/media/music:/media/music:ro
   ```
4. Rebuild (`make server-switch`)
5. In Immich admin UI, create an external library pointing to `/media/music`

## Immich data flow
- **Originals** (HDD): `/media/pictures/`, `/media/videos/`
- **Working set** (NVMe): `/persist/immich/library/` — thumbnails, encoded video, faces, internal uploads
- **Database** (NVMe): `/persist/immich/postgres/`
- **ML cache** (NVMe): `/persist/immich/model-cache/`

## Data placement guide

| Content | Put it here | Why |
|---------|-------------|-----|
| Photos from camera | `/media/pictures/` | Warm tier, originals |
| Videos from camera | `/media/videos/home/` | Warm tier, originals |
| Downloaded movies | `/media/videos/movies/` | Warm tier, large files |
| Music files | `/media/music/` | Warm tier, originals |
| E-books | `/media/documents/books/` | Warm tier, small files |
| AI model weights | `/media/ai/llama-models/` | Warm tier, large files |
| Downloads in progress | `/downloads/` | Transient tier |
| Immich thumbnails | `/persist/immich/library/` | Hot tier, app-generated |
| Immich database | `/persist/immich/postgres/` | Hot tier, fast access needed |
| Working files | `/data/working/` | Hot tier, temporary |
