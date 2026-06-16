---
name: nixvim-project-overrides
description: This skill should be used when configuring project-specific Neovim (nixvim) setups with per-project LSP servers, plugins, or settings. It covers extracting a shared base config, using makeNixvim for standalone project-specific Neovim packages, and managing per-project LSP servers in Nix flakes. Use this when a user wants to move global nixvim configuration (like qmlls, pyright, rust-analyzer) to a project-specific devShell, or when setting up a project-local Neovim with different features than the global one.
---

# Nixvim Project-Specific Overrides

## Overview

This skill enables per-project Neovim customization using the nixvim flake input. Instead of installing all LSP servers and plugins globally in Home Manager, this pattern allows projects to declare their own Neovim with only the tools they need. The global Neovim remains lightweight, while project-specific builds extend the shared base config with additional LSP servers, plugins, or settings.

## When to Use This Skill

- Moving a global LSP server (e.g., qmlls, pyright, rust-analyzer) to only the projects that need it
- Setting up a project-specific Neovim with different colorschemes or plugins
- Creating a development shell where `nvim` automatically uses project-specific tooling
- Building a standalone Neovim package for a specific project (not via Home Manager)

## Prerequisites

- The NixOS flake must have `nixvim` as an input (already configured in `flake.nix`)
- The global nixvim config should be extracted to a reusable `base.nix` file
- Basic understanding of Nix flakes and `nix develop` / `nix-shell`

## Core Workflow

### Step 1: Extract Shared Base Config

Move the common nixvim configuration from the Home Manager module into a reusable `base.nix` file. This file contains everything except Home Manager-specific settings and project-specific overrides.

**What to include in `base.nix`:**
- Colorschemes (`colorschemes.catppuccin`)
- Editor settings (`opts`, `globals`, `keymaps`, `diagnostic.settings`)
- Shared plugins (`treesitter`, `blink-cmp`, `snacks`, `yazi`, `hardtime`, `nix`)
- Shared LSP servers that are useful everywhere (`nil_ls` for Nix files)
- Shared LSP keymaps and format settings

**What to exclude from `base.nix`:**
- Home Manager-specific settings (`enable`, `defaultEditor`, `vimAlias`, `viAlias`)
- Project-specific LSP servers (`qmlls`, `pyright`, `rust-analyzer`, etc.)
- Project-specific plugins

**Example base config structure:**

```
modules/home/cookiegigi/programs/nixvim.nix      # Home Manager wrapper
modules/home/cookiegigi/programs/nixvim/
  └── base.nix                                   # Shared config
```

**Home Manager wrapper (`nixvim.nix`):**
```nix
_: {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;

    imports = [
      ./nixvim/base.nix
    ];
  };
}
```

### Step 2: Build Project-Specific Neovim

In the project's `flake.nix` (or the NixOS repo's root `flake.nix` for the NixOS config itself), use `nixvim.legacyPackages.${system}.makeNixvim` to create a standalone Neovim package.

**Key points:**
- `makeNixvim` takes a nixvim-style attrset and returns a regular Nix derivation
- The returned derivation can be used in `buildInputs`, `packages`, or `environment.systemPackages`
- The `imports` key accepts a list of nixvim module files to include
- Additional settings are merged on top of the imported base config

**Example in `flake.nix`:**

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixvim.url = "github:nix-community/nixvim";
    # ... other inputs
  };

  outputs = { self, nixpkgs, nixvim, ... }: {
    devShells.x86_64-linux.default = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      # Project-specific Neovim with qmlls for QML development
      projectNvim = nixvim.legacyPackages.x86_64-linux.makeNixvim {
        imports = [
          ./modules/home/cookiegigi/programs/nixvim/base.nix
        ];
        plugins.lsp.servers.qmlls = {
          enable = true;
          package = pkgs.kdePackages.qttools;
        };
      };
    in
      pkgs.mkShell {
        buildInputs = [
          # ... other tools
          projectNvim
        ];
      };
  };
}
```

### Step 3: How It Works in Practice

When inside a `nix develop` shell:

1. The `PATH` variable prioritizes the devShell's packages over global system packages
2. Running `nvim` uses the `projectNvim` build, which includes all base settings + project-specific overrides
3. Outside the shell, running `nvim` uses the global Home Manager build (lighter, without project-specific servers)

**Verify the correct nvim is active:**
```bash
# Inside the devShell
which nvim
# Should show a path in /nix/store/..., not ~/.nix-profile/bin/nvim

# Check LSP servers
:nvim --headless -c "lua print(vim.inspect(require('lspconfig').util.available_servers()))" -c "qa"
```

## Common Patterns

### Adding Multiple LSP Servers

```nix
projectNvim = nixvim.legacyPackages.x86_64-linux.makeNixvim {
  imports = [ ./modules/home/cookiegigi/programs/nixvim/base.nix ];
  plugins.lsp.servers = {
    qmlls = {
      enable = true;
      package = pkgs.kdePackages.qttools;
    };
    # Add other project-specific servers
  };
};
```

### Adding Project-Specific Plugins

```nix
projectNvim = nixvim.legacyPackages.x86_64-linux.makeNixvim {
  imports = [ ./modules/home/cookiegigi/programs/nixvim/base.nix ];
  plugins = {
    # Project-specific plugins
    lsp.servers.qmlls = {
      enable = true;
      package = pkgs.kdePackages.qttools;
    };
  };
};
```

### Using in a Different Project's Flake

For a project outside the NixOS repo (e.g., `~/Projects/my-project/flake.nix`):

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixvim.url = "github:nix-community/nixvim";
  };

  outputs = { self, nixpkgs, flake-utils, nixvim, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      myProjectNvim = nixvim.legacyPackages.${system}.makeNixvim {
        # Define a minimal config or import from a local file
        colorschemes.tokyonight.enable = true;
        plugins.lsp.servers.pyright.enable = true;
      };
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = [ myProjectNvim pkgs.python3 ];
      };
    });
}
```

## Important Notes

- **Git tracking**: New files referenced by `imports` in `makeNixvim` must be tracked by git (`git add`) or Nix will not see them in flakes
- **Formatting**: Run `nix fmt` after editing nixvim configs to ensure consistent formatting
- **Validation**: Run `nix flake check --no-build` to verify the flake evaluates correctly without building
- **PATH priority**: The devShell's `nvim` shadows the global one. If you need the global one inside the shell, use the full path `~/.nix-profile/bin/nvim`
- **No rebuild needed**: Since this is a devShell package (not a NixOS system package), no `nixos-rebuild` is required. Just `nix develop` or `direnv reload`

## Troubleshooting

**Error: "Path does not exist in Git repository"**
- Run `git add <path-to-base.nix>` to stage the file
- Flakes only see files tracked by git

**Error: "Path is not tracked by Git"**
- Same fix: `git add` the file. Uncommitted files in a flake are invisible to Nix.

**Wrong nvim inside devShell**
- Run `which nvim` to verify which binary is first in PATH
- Ensure `projectNvim` is in the devShell's `buildInputs` (not `nativeBuildInputs`)

## Resources

- Nixvim documentation: https://nix-community.github.io/nixvim/
- `makeNixvim` reference: Build standalone Neovim packages from nixvim configs
- `makeNixvimWithModule`: Advanced usage with full module system and `extraSpecialArgs`
