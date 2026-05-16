{pkgs, ...}: let
  inherit (import ../lib.nix {inherit pkgs;}) mkSkill;
in
  mkSkill "nixos-rebuild" "How to build, test, and switch NixOS configurations safely" ''
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
  ''
