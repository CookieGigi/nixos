---
name: server-storage-layout
description: Tiered server storage architecture with hot/warm/cold/transient tiers, BTRFS, and permissions
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  domain: system-administration
---

## What I do
- Define the server storage tier architecture (hot/warm/cold/transient)
- Document directory layout, mount points, and BTRFS subvolumes
- Specify permission models and shared group conventions
- Guide adding new directories or storage tiers

## Hardware

| Device | LUKS | BTRFS subvolume | Mount | Tier | Use |
|--------|------|-----------------|-------|------|-----|
| NVMe (`/dev/nvme0n1`) | `cookieluks` | `@persist` | `/persist` | Hot | App databases, caches, working files, system state |
| HDD (`/dev/sda`) | `medialuks` | `@media` | `/media` | Warm | Original media (photos, videos, music, documents) |
| HDD (`/dev/sda`) | `medialuks` | `@backup` | `/backup` | Cold | BTRFS snapshots, long-term backups |
| HDD (`/dev/sda`) | `medialuks` | `@downloads` | `/downloads` | Transient | Staging area, temporary downloads |

## Tier philosophy

| Tier | Speed | Persistence | Content | Examples |
|------|-------|-------------|---------|----------|
| **Hot** (NVMe) | Fast | Permanent | App-generated data | DBs, thumbnails, caches, search indices |
| **Warm** (HDD) | Slow | Permanent | Original content | Photos, videos, music, documents, AI models |
| **Cold** (HDD) | Slow | Permanent | Snapshots | BTRFS read-only snapshots of `@media` |
| **Transient** (HDD) | Slow | Ephemeral | Downloads | Staging before sorting into warm tier |

## Directory layout

### Hot tier — `/persist` (NVMe)

Owned by service users. Each app gets its own subtree:

```
/persist/
├── immich/
│   ├── library/         # immich:immich (thumbnails, encoded video, faces)
│   ├── model-cache/     # immich:immich (ML model cache)
│   └── postgres/        # immich-db:immich-db (database files, 0700)
├── proton-drive/
│   └── sync-state/      # root:root (sync metadata)
└── backups/
    └── snapshot-timestamps/  # root:root
```

### Hot tier — `/data` (NVMe, optional working space)

```
/data/
├── cache/               # root:root (general cache)
├── hot-media/           # root:media (frequently accessed media)
└── working/
    └── ingest/          # root:media (staging for processing)
```

### Warm tier — `/media` (HDD)

Organized by **content type**, not by application. All directories use `2775 root:media` (setgid so new files inherit the `media` group):

```
/media/
├── pictures/            # Original photos (Immich external library)
├── videos/
│   ├── home/            # Home videos
│   ├── movies/          # Movies
│   ├── shows/           # TV shows
│   ├── clips/           # Short clips
│   └── music-videos/    # Music videos
├── music/               # Music files
├── documents/
│   ├── books/           # E-books
│   ├── papers/          # Academic papers
│   └── receipts/        # Scanned receipts
└── ai/
    ├── llama-models/    # root:ai (2770) — AI model weights
    └── llama-mmproj/    # root:ai (2770) — Vision projectors
```

### Cold tier — `/backup` (HDD)

```
/backup/
└── media-snapshots/     # root:root — BTRFS snapshots of @media
```

### Transient tier — `/downloads` (HDD)

```
/downloads/              # root:media (2775) — staging area
```

## Permission model

### Shared groups

| Group | GID | Members | Purpose |
|-------|-----|---------|---------|
| `media` | 200 | `cookiegigi`, `immich` | Read/write access to `/media/*` and `/downloads` |
| `ai` | 202 | `cookiegigi`, `llama` | Read access to `/media/ai/*` |
| `immich-services` | 201 | `immich`, `immich-db` | Shared secret access between Immich services |

### Permission patterns

| Pattern | Octal | Use case |
|---------|-------|----------|
| `2775 root:media` | Setgid + rwxrwxr-x | Shared media directories — new files inherit `media` group |
| `2770 root:ai` | Setgid + rwxrwx--- | Restricted shared directories (AI models) |
| `0755 user:user` | rwxr-xr-x | Service-owned app data (single user) |
| `0700 user:user` | rwx------ | Sensitive service data (databases) |
| `0750 root:group` | rwxr-x--- | Restricted read access |

### Why setgid (2xxx)?

Setgid ensures that files created by any user in the directory inherit the directory's group. This means:
- `cookiegigi` writes to `/media/pictures/` → file is `cookiegigi:media`
- `immich` container (running as `immich:immich`) can read it via the `media` group
- No need for world-readable permissions

## Adding a new directory

1. **Decide the tier** — hot (NVMe `/persist` or `/data`) or warm (HDD `/media`)
2. **Decide the permission model**:
   - Shared read access → `2775 root:media` (or `2770 root:<group>` for restricted)
   - Service-only → `0755 <user>:<group>`
   - Sensitive → `0700 <user>:<group>`
3. **Add tmpfiles rule** in the appropriate module:
   - Shared warm directories → `modules/server/storage-layout.nix`
   - Service-owned hot directories → `modules/server/containers/<service>/users.nix`
4. **Add container mount** if a container needs access
5. **Run `nix fmt` and rebuild**

## Example: adding `/media/datasets`

```nix
# In modules/server/storage-layout.nix
systemd.tmpfiles.rules = [
  "d /media/datasets 2775 root media -"
  # ...
];

# In container definition
Volume=/media/datasets:/media/datasets:ro
```

## BTRFS snapshots (cold tier)

`/backup/media-snapshots/` holds read-only BTRFS snapshots of the `@media` subvolume:
- Use `btrfs subvolume snapshot -r /media /backup/media-snapshots/<timestamp>`
- Automate via systemd timer (recommended: daily)
- Send to Proton Drive for off-site backup (weekly)

## Rules
1. **Organize by content type, not application** — `/media/pictures/`, not `/media/immich/`
2. **Originals on HDD, derived data on NVMe** — keep `/media/` for source files only
3. **Use shared groups, not world-readable** — `2775` + `media` group instead of `0755`
4. **Containers mount warm tier read-only by default** — change to `:rw` only if write access is needed
5. **Every stateful path must have a tmpfiles rule** — ensures directory exists after reboot on ephemeral root
