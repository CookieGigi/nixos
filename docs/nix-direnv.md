# nix-direnv — Per-Project Nix Shells

> Automatically load project-specific Nix environments when you `cd` into a directory, using [nix-direnv](https://github.com/nix-community/nix-direnv).

---

## What It Does

[nix-direnv](https://github.com/nix-community/nix-direnv) is a faster, persistent implementation of direnv's `use_nix` and `use_flake`. When you enter a project directory, it automatically loads the Nix shell environment. Key features:

- **Significantly faster** after the first run (caches the shell environment)
- **Prevents garbage collection** by symlinking build dependencies into your gcroots
- No external daemon needed (unlike lorri)

---

## How It Works in This Repo

This NixOS flake already has nix-direnv enabled via home-manager:

- **Config**: [`modules/home/cookiegigi/programs/nix-direnv.nix`](../modules/home/cookiegigi/programs/nix-direnv.nix)
- **Shell integration**: Zsh (via `programs.direnv.enableZshIntegration = true`)

When you `cd` into `~/nixos`, direnv detects the `.envrc` and loads the flake's `devShells.default`.

---

## Quick Start for a New Project

### Flake-based project (recommended)

Inside your new project directory:

```bash
# 1. Create a flake with a devShell (if you don't have one)
nix flake init -t github:nix-community/nix-direnv

# 2. Create the direnv config
echo "use flake" > .envrc

# 3. Allow direnv to load it
direnv allow
```

That's it. Every time you `cd` into this directory, your devShell loads automatically.

### Existing flake

If the project already has a `flake.nix` with a `devShells.default`:

```bash
echo "use flake" > .envrc
direnv allow
```

You can also target a specific flake output:

```bash
echo "use flake ~/myflakes#project" > .envrc
direnv allow
```

### Non-flake project (shell.nix)

Create a `shell.nix`:

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = [ pkgs.hello pkgs.cargo pkgs.rustc ];
}
```

Then:

```bash
echo "use nix" > .envrc
direnv allow
```

You can also use a non-standard filename:

```bash
echo "use nix foo.nix" > .envrc
direnv allow
```

---

## This Repo (`~/nixos`)

This repository already contains:

- `.envrc` with `use flake`
- `flake.nix` defines `devShells.x86_64-linux.default` containing:
  - `alejandra` — Nix formatter
  - `git`
  - `sops` — secret editing
  - `age` — encryption tool

So when you `cd ~/nixos`, you automatically get these tools in your PATH.

---

## Common Commands

| Command | Description |
|---------|-------------|
| `direnv allow` | Approve `.envrc` loading in current directory |
| `direnv deny` | Revoke approval |
| `direnv reload` | Force reload the environment |
| `nix-direnv-reload` | Reload only the nix environment (when in manual mode) |

---

## Advanced Options

### Manual reload mode

To avoid unexpected rebuilds, nix-direnv can tell you when the env is stale and let you decide when to reload:

```bash
# In your .envrc
nix_direnv_manual_reload
use flake
```

Then run `nix-direnv-reload` when you want to update.

### Watch additional files

By default, nix-direnv watches `flake.nix`, `flake.lock`, and `.envrc`. To watch more:

```bash
# In your .envrc
watch_file devshell.toml
use flake
```

### Disable fallback

By default, nix-direnv reloads the last working devShell if the new one fails. To disable:

```bash
nix_direnv_disallow_fallback
use flake
```

### Pass extra arguments to `nix print-dev-env`

```bash
# Example: impure evaluation
echo "use flake . --impure" > .envrc
```

---

## Tracked Files (Auto-Watched)

nix-direnv automatically tells direnv to watch these files:

**For `use flake`:**
- `~/.direnvrc`
- `~/.config/direnv/direnvrc`
- `.envrc`
- `flake.nix`
- `flake.lock`
- `devshell.toml` (if it exists)

**For `use nix`:**
- `~/.direnvrc`
- `~/.config/direnv/direnvrc`
- `.envrc`
- `default.nix` or `shell.nix`

---

## What Gets Ignored

`.direnv/` is excluded from git (already in the global git ignore via home-manager, and also in this repo's `.gitignore`). This directory contains direnv's cache and should never be committed.

---

## Reference

- nix-direnv README: https://github.com/nix-community/nix-direnv
- direnv docs: https://direnv.net/
- flake template: `nix flake new -t github:nix-community/nix-direnv <path>`
