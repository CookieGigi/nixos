{pkgs, ...}: {
  agentsMd = pkgs.writeText "AGENTS.md" ''
    > **Note:** This global `~/.config/opencode` directory is managed by the NixOS configuration (`modules/home/cookiegigi/programs/opencode/`). Do not edit files here manually -- changes will be overwritten on the next `nixos-rebuild`.

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
}
