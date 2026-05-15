# WARN: This file is the single source of truth for the global OpenCode configuration.
# Always edit THIS Nix file; the live ~/.config/opencode files are generated from here.
# Nix is the source of truth for global config.
{
  pkgs,
  lib,
  ...
}: let
  opencodeConfig = (pkgs.formats.json {}).generate "opencode.json" {
    agent = {
      explaining = {
        model = "opencode-go/kimi-k2.6";
        mode = "primary";
        description = "Read and execute non-destructive commands to answer questions in a pedagogical way";
        prompt = ''
          You are a pedagogical explaining agent. Your goal is to help the user understand concepts by reading relevant files and executing safe, non-destructive commands.
          Never edit or delete files. Always explain your reasoning step by step. Use bash, read, glob, grep, webfetch, and websearch tools as needed.
          When running commands, prefer read-only operations (cat, ls, grep, find, etc.). Avoid any command that modifies the filesystem.
        '';
        permission = {
          read = "allow";
          bash = "allow";
          glob = "allow";
          grep = "allow";
          webfetch = "allow";
          websearch = "allow";
          task = "allow";
          lsp = "allow";
          skill = "allow";
          question = "allow";
          todowrite = "allow";
          edit = "deny";
          external_directory = "ask";
        };
        steps = 20;
        color = "info";
      };

      configuration = {
        model = "opencode-go/deepseek-v4-pro";
        mode = "primary";
        description = "Nix/NixOS and project configuration expert that stays in the Nix way";
        prompt = ''
          You are a Nix and system configuration expert. You help with NixOS configuration, Nix flakes, and project setup following Nix conventions.
          You prefer declarative configuration over imperative changes. When suggesting edits to Nix files, ensure they follow the existing style (alejandra formatting) and use proper Nix patterns.
          Always suggest changes that fit within the existing module structure. Use read, bash, glob, grep, and lsp tools to explore the codebase before making recommendations.
        '';
        permission = {
          read = "allow";
          bash = "allow";
          glob = "allow";
          grep = "allow";
          webfetch = "allow";
          websearch = "allow";
          task = "allow";
          lsp = "allow";
          skill = "allow";
          question = "allow";
          todowrite = "allow";
          edit = "ask";
          external_directory = "ask";
        };
        steps = 20;
        color = "success";
      };
    };

    model = "opencode-go/kimi-k2.6";
    small_model = "opencode-go/deepseek-v4-flash";
    default_agent = "build";

    tui = {
      theme = "catppuccin";
    };

    tools = {
      lsp = true;
    };

    formatter = {
      nix = {
        command = ["nix" "fmt" "."];
        extensions = [".nix"];
      };
    };

    lsp = {
      nix = {
        command = ["${pkgs.nil}/bin/nil"];
        extensions = [".nix"];
      };
    };

    mcp = {
      duckduckgo = {
        type = "local";
        command = ["npx" "-y" "duckduckgo-mcp-server"];
        enabled = true;
      };
      context7 = {
        type = "remote";
        url = "https://mcp.context7.com/mcp";
        enabled = true;
      };
    };

    skills = {
      paths = ["/home/cookiegigi/.config/opencode/skills"];
    };

    plugin = ["@tarquinen/opencode-dcp@latest"];

    username = "cookiegigi";
  };

  agentsMd = pkgs.writeText "AGENTS.md" ''
    > **Note:** This global `~/.config/opencode` directory is managed by the NixOS configuration (`modules/programs/opencode.nix`). Do not edit files here manually -- changes will be overwritten on the next `nixos-rebuild`.

    # AGENTS.md -- Global Agent Context

    ## System Overview

    This machine runs **NixOS**, a declarative Linux distribution managed entirely through configuration files. All system-level software, services, kernel modules, and user environments are defined in `.nix` files and applied atomically via `nixos-rebuild`.

    - **No imperative package management**: Do not use `apt`, `brew`, `pip --user`, `npm -g`, or manual installations for system-wide tools.
    - **Everything is in the flake**: If a tool or service is needed system-wide, it must be declared in the NixOS configuration repository and rebuilt.
    - **Home directory is ephemeral**: The root filesystem is tmpfs (impermanence). Persistent data must be explicitly declared in `environment.persistence."/persist"` or it will be lost on reboot.

    ## NixOS Configuration Repository

    The system configuration lives in `~/nixos/`:
    - **Flake-based**, uses `nixos-unstable`
    - **Host**: `xps` (x86_64-linux)
    - **Entrypoint**: `flake.nix`
    - **Modules**: `modules/` contains reusable NixOS modules (core, desktop, audio, programs, users, etc.)
    - **Host-specific**: `hosts/xps/` contains hardware and disk configuration
    - **Impermanence**: `/` is tmpfs; persistent data lives on BTRFS subvolume `@persist` mounted at `/persist`
    - **Disko**: declarative disk layout (LUKS + BTRFS)

    ### Key Commands
    - Apply config: `sudo nixos-rebuild switch --flake ~/nixos#xps`
    - Build without switching: `sudo nixos-rebuild build --flake ~/nixos#xps`
    - Check flake: `nix flake check ~/nixos`
    - Format `.nix` files: `nix fmt ~/nixos` (uses alejandra)

    ## Working on Projects

    When working on a project *outside* the NixOS config repository:

    ### System-wide packages or global configuration
    If a project needs a tool, service, or system-level config that affects the whole machine:

    1. **Do NOT install imperatively** (no `apt`, `brew`, `pip install --user`, `npm install -g`, etc.)
    2. **Add it to the NixOS flake** in the appropriate module under `~/nixos/modules/` (e.g., `modules/programs/...`, `modules/users/cookiegigi.nix`)
    3. **Document it** in `~/nixos/docs/<project-name>.md` so the dependency is tracked
    4. **Rebuild** with `sudo nixos-rebuild switch --flake ~/nixos#xps`

    ### Project-local tools or language dependencies
    Prefer keeping dependencies local to the project when possible:

    - Use `flake.nix` / `shell.nix` within the project for development shells
    - Use language-specific lockfiles (`package-lock.json`, `Cargo.lock`, `poetry.lock`, `go.mod`, etc.)
    - Use project-local package managers
    - Use container tools (`docker`, `podman`) if the project already supports them

    ### Rule of Thumb
    - **Affects the whole system or needs to persist across reboots** -> belongs in `~/nixos`
    - **Only matters while working inside a specific project** -> keep it local to that project

    ## Agent Behavior Rules

    - **Never execute `sudo nixos-rebuild` yourself**. Always ask the user for explicit permission before running any `nixos-rebuild` command (switch, build, test, etc.). The user must approve each rebuild.

    ## Important Warnings

    - `hardware-configuration.nix` is auto-generated -- do not edit it manually
    - `boot.kernelPackages = pkgs.linuxPackages_latest` tracks the latest kernel, which can occasionally cause regressions
    - Any new stateful paths (dotfiles, data dirs) must be explicitly added to impermanence config or they vanish on reboot
  '';

  tuiJson = (pkgs.formats.json {}).generate "tui.json" {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "catppuccin";
  };

  skillImpermanence = pkgs.writeText "SKILL.md" ''
    ---
    name: impermanence
    description: How ephemeral root and impermanence work on this NixOS host
    license: MIT
    compatibility: opencode
    metadata:
      audience: nixos-users
      domain: system-administration
    ---

    ## What I do
    - Explain that `/` is tmpfs and wiped on reboot
    - Describe the `/persist` mount and BTRFS subvolume `@persist`
    - Show how to declare persistent paths via `environment.persistence."/persist"`
    - Warn when a new stateful path is missing from persistence config

    ## When to use me
    Use this skill when the user asks about data persistence, where to store config, or why something disappeared after reboot.

    ## Key conventions
    - Any dotfile, data dir, or state must be in `environment.persistence."/persist"` or it vanishes
    - Common paths: `~/.config`, `~/.local/share`, `~/.local/state`, `~/.ssh`
    - The persistence module is defined in `modules/core.nix` and `modules/users/cookiegigi.nix`
    - Always add new persistent paths to the NixOS config, not manually
  '';

  skillNixBasics = pkgs.writeText "SKILL.md" ''
    ---
    name: nix-basics
    description: Core Nix concepts including the Nix language, flakes, and pure functional package management
    license: MIT
    compatibility: opencode
    metadata:
      audience: nix-users
      domain: system-configuration
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
  '';

  skillNixosRebuild = pkgs.writeText "SKILL.md" ''
    ---
    name: nixos-rebuild
    description: How to build, test, and switch NixOS configurations safely
    license: MIT
    compatibility: opencode
    metadata:
      audience: nixos-users
      domain: system-administration
    ---

    ## What I do
    - Explain `nixos-rebuild switch`, `build`, and `test` differences
    - Guide safe rebuild practices (build first, then switch)
    - Help read `nixos-rebuild` output and errors
    - Suggest rollback strategies (`nixos-rebuild switch --rollback`)

    ## When to use me
    Use this skill when the user needs to rebuild NixOS, troubleshoot a failed build, or understand rebuild commands.

    ## Key conventions
    - Always run `nix fmt` before rebuilding if the repo has a formatter
    - Build first: `sudo nixos-rebuild build --flake .#xps`
    - Switch after verifying: `sudo nixos-rebuild switch --flake .#xps`
    - Use `nix flake check` to validate the flake without building
    - Keep generations so you can roll back if something breaks
  '';
in {
  environment.systemPackages = [
    pkgs.opencode
    pkgs.nodejs
    pkgs.nil
  ];

  # Overwrite managed config files on every activation so the live
  # ~/.config/opencode always matches this Nix declaration.
  system.activationScripts.opencode-config = ''
    mkdir -p /home/cookiegigi/.config/opencode
    mkdir -p /home/cookiegigi/.config/opencode/skills/impermanence
    mkdir -p /home/cookiegigi/.config/opencode/skills/nix-basics
    mkdir -p /home/cookiegigi/.config/opencode/skills/nixos-rebuild

    cp -f ${opencodeConfig} /home/cookiegigi/.config/opencode/opencode.json
    cp -f ${agentsMd} /home/cookiegigi/.config/opencode/AGENTS.md
    cp -f ${tuiJson} /home/cookiegigi/.config/opencode/tui.json
    cp -f ${skillImpermanence} /home/cookiegigi/.config/opencode/skills/impermanence/SKILL.md
    cp -f ${skillNixBasics} /home/cookiegigi/.config/opencode/skills/nix-basics/SKILL.md
    cp -f ${skillNixosRebuild} /home/cookiegigi/.config/opencode/skills/nixos-rebuild/SKILL.md

    chown -R cookiegigi:users /home/cookiegigi/.config/opencode
    chmod 644 /home/cookiegigi/.config/opencode/opencode.json
    chmod 644 /home/cookiegigi/.config/opencode/AGENTS.md
    chmod 644 /home/cookiegigi/.config/opencode/tui.json
    chmod 644 /home/cookiegigi/.config/opencode/skills/impermanence/SKILL.md
    chmod 644 /home/cookiegigi/.config/opencode/skills/nix-basics/SKILL.md
    chmod 644 /home/cookiegigi/.config/opencode/skills/nixos-rebuild/SKILL.md

    # Clean up legacy filename if it exists
    if [ -f /home/cookiegigi/.config/opencode/.opencode.json ]; then
      rm -f /home/cookiegigi/.config/opencode/.opencode.json
    fi
  '';

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/home/cookiegigi/.config/opencode"
      "/home/cookiegigi/.local/share/opencode"
      "/home/cookiegigi/.local/state/opencode"
    ];
  };
}
