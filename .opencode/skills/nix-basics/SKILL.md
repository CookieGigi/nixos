---
name: nix-basics
description: Core Nix concepts including the Nix language, flakes, and pure functional package management
license: MIT
compatibility: opencode
metadata:
  audience: nixos-users
  domain: system-administration
---

## What I do
- Explain Nix language syntax (functions, attrsets, let-in, with, imports)
- Describe how Nix flakes work (inputs, outputs, nix flake commands)
- Clarify pure functional evaluation and why it matters
- Help understand nixpkgs overlays, lib functions, and common patterns

## When to use me
Use this skill when the user asks about Nix fundamentals, language syntax, or how the Nix ecosystem works.

## Key conventions
- Nix files are pure: no side effects during evaluation
- Flakes lock dependencies in `flake.lock`
- Use `lib` helpers from `nixpkgs.lib` instead of reinventing logic
- Prefer `let` bindings over deeply nested expressions
