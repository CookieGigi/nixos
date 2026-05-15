---
name: disko-layout
description: Declarative disk partitioning with LUKS and BTRFS via disko
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  domain: system-administration
---

## What I do
- Explain the disko layout in `hosts/xps/disko.nix`
- Describe LUKS encryption (`cookieluks`) and BTRFS subvolumes
- Clarify that disko.nix is only for initial install, not regular rebuilds
- Warn against changing disk device paths unless hardware changed

## When to use me
Use this skill when the user asks about disk setup, partitioning, or the disko module.

## Key conventions
- Device: `/dev/nvme0n1`
- LUKS name: `cookieluks`
- BTRFS subvolumes: `@persist`, `@nix`, `@snapshots`
- `/` is tmpfs (4G), `/persist` is BTRFS
- Do not change `disko.nix` after installation unless repartitioning
