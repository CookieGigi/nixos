{pkgs, ...}: let
  inherit (import ../lib.nix {inherit pkgs;}) mkSkill;
in
  mkSkill "impermanence" "How ephemeral root and impermanence work on this NixOS host" ''
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
  ''
