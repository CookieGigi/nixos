{pkgs, ...}: let
  copilotWrapper = pkgs.writeShellApplication {
    name = "copilot";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      path_entries=()
      resolved_path=()
      IFS=: read -r -a path_entries <<< "$PATH"
      for entry in "''${path_entries[@]}"; do
        if [[ -d "$entry" ]]; then
          resolved_path+=("$(realpath -- "$entry")")
        else
          resolved_path+=("$entry")
        fi
      done
      PATH="$(IFS=:; printf '%s' "''${resolved_path[*]}")"
      export PATH
      # Prevent NixOS login-shell setup from re-adding the symlinked profile path.
      export __NIXOS_SET_ENVIRONMENT_DONE=1
      exec ${pkgs.github-copilot-cli}/bin/copilot "$@"
    '';
  };
in {
  home.packages = with pkgs; [
    wget
    copilotWrapper
    github-copilot-app
  ];
}
