---
name: nixos-config
description: Architecture and conventions of this NixOS flake repository
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  domain: project-configuration
---

## What I do
- Explain the repo layout (flake.nix, hosts/xps/, modules/)
- Describe how modules are imported and composed
- Point to important files: core.nix, disko.nix, hardware-configuration.nix
- Remind that hardware-configuration.nix is auto-generated and should not be edited

## When to use me
Use this skill when working inside this NixOS repository to understand its structure and conventions.

## Key conventions
- Host-specific config lives in `hosts/xps/`
- Reusable modules live in `modules/`
- User config is in `modules/users/cookiegigi.nix`
- Programs are added under `modules/programs/`
- Formatter: `alejandra` (run `nix fmt`)
- Do not edit `hardware-configuration.nix` manually
- `boot.kernelPackages = pkgs.linuxPackages_latest` tracks latest kernel
