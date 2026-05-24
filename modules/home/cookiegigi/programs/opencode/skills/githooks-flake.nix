{pkgs, ...}: let
  inherit (import ../lib.nix {inherit pkgs;}) mkSkill;
in
  mkSkill "githooks-flake"
  "Set up pre-commit hooks in a Nix flake using git-hooks.nix (cachix)"
  ''
    ## What I do
    - Explain how to add pre-commit hooks to a Nix flake project using `github:cachix/git-hooks.nix`
    - Provide a ready-to-use flake pattern that defines checks, formatter, and devShell integration
    - Cover the `core.hooksPath` guard needed when users have a global git hooks path set

    ## When to use me
    Use this skill when setting up or modifying pre-commit hooks in a Nix flake project, or when a dev shell is not installing hooks correctly.

    ## Minimal flake pattern

    Add `git-hooks` as a flake input:

    ```nix
    {
      inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        git-hooks = {
          url = "github:cachix/git-hooks.nix";
          inputs.nixpkgs.follows = "nixpkgs";
        };
      };
    }
    ```

    In `outputs`, define the check, formatter, and devShell:

    ```nix
    outputs = { self, nixpkgs, git-hooks, ... }:
      let
        system = "x86_64-linux";
      in {
        checks.''${system}.pre-commit-check = git-hooks.lib.''${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            statix.enable = true;
            deadnix = {
              enable = true;
              excludes = [ "hardware-configuration" ];
            };
            flake-checker.enable = true;
            end-of-file-fixer.enable = true;
            trim-trailing-whitespace.enable = true;
            check-merge-conflicts.enable = true;
          };
        };

        formatter.''${system} =
          let
            pkgs = nixpkgs.legacyPackages.''${system};
            config = self.checks.''${system}.pre-commit-check.config;
            inherit (config) package configFile;
          in
            pkgs.writeShellScriptBin "pre-commit-run" '''
              ''${pkgs.lib.getExe package} run --all-files --config ''${configFile}
            ''';

        devShells.''${system}.default =
          let
            pkgs = nixpkgs.legacyPackages.''${system};
            inherit (self.checks.''${system}.pre-commit-check) shellHook enabledPackages;
          in
            pkgs.mkShell {
              shellHook = '''
                # Guard against global core.hooksPath which breaks pre-commit hook installation.
                _global_hooksPath="$(''${pkgs.git}/bin/git config --global core.hooksPath 2>/dev/null || true)"
                if [ -n "$_global_hooksPath" ]; then
                  echo ""
                  echo "WARNING: core.hooksPath is set globally ('$_global_hooksPath')."
                  echo "This prevents pre-commit hooks from being installed by the Nix devShell."
                  echo "Remove it with: git config --global --unset-all core.hooksPath"
                  echo ""
                fi
                unset _global_hooksPath

                ''${shellHook}
              ''';
              buildInputs = enabledPackages;
            };
      };
    ```

    ## Key points

    - `git-hooks.lib.<system>.run` takes `src` (usually `./.`) and a `hooks` attrset.
    - Available hooks are documented upstream: https://github.com/cachix/git-hooks.nix
    - `self.checks.<system>.pre-commit-check` exposes `shellHook` and `enabledPackages`.
    - Import `shellHook` into the devShell so entering the shell auto-installs hooks.
    - The `core.hooksPath` guard is **required** if you (or another tool) has set a global hooks path; git-hooks.nix only unsets the local config.
    - `formatter` reuses the pre-commit check config so `nix fmt` runs the same linters.

    ## Usage

    1. Enter the devShell: `nix develop`
    2. Hooks are installed automatically on shell entry.
    3. Run checks manually: `nix flake check`
    4. Run formatter manually: `nix fmt`

    ## Troubleshooting

    **Hooks not installing:**
    Check `git config --global core.hooksPath`. If set, unset it globally.

    **Formatter not found:**
    Make sure `formatter.<system>` is defined in the flake outputs.

    **Hook fails on generated files:**
    Use the `excludes` option (e.g. `deadnix.excludes = [ "hardware-configuration" ];`).
  ''
