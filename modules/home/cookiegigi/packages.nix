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
  githubCopilotApp = pkgs.github-copilot-app.overrideAttrs (old: {
    nativeBuildInputs =
      (old.nativeBuildInputs or [])
      ++ pkgs.lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [pkgs.python3];
    preFixup =
      (old.preFixup or "")
      + pkgs.lib.optionalString (pkgs.stdenv.hostPlatform.system == "x86_64-linux") ''
        # Preserve the upstream relocation before autoPatchelf rewrites it.
        ${pkgs.python3}/bin/python3 ${../../../scripts/fix-elf-relacount.py} capture "$out/bin/github-copilot-app" "$TMPDIR/copilot-relocation.bin"
        postFixupHooks+=(repairCopilotRelacount)
        repairCopilotRelacount() {
          ${pkgs.python3}/bin/python3 ${../../../scripts/fix-elf-relacount.py} repair "$out/bin/.github-copilot-app-wrapped" "$TMPDIR/copilot-relocation.bin"
        }
      '';
  });
in {
  home.packages = with pkgs; [
    wget
    copilotWrapper
    githubCopilotApp
  ];
}
