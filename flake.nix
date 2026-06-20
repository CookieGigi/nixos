{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    nur = {
      url = "github:nix-community/NUR/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pixie-sddm = {
      url = "github:xCaptaiN09/pixie-sddm";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
    };
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    impermanence,
    home-manager,
    nixos-hardware,
    nur,
    sops-nix,
    pixie-sddm,
    git-hooks,
    nixvim,
    ...
  }: {
    checks.x86_64-linux.pre-commit-check = git-hooks.lib.x86_64-linux.run {
      src = ./.;
      hooks = {
        alejandra.enable = true;
        statix.enable = true;
        deadnix = {
          enable = true;
          excludes = ["hardware-configuration"];
        };
        flake-checker.enable = true;
        end-of-file-fixer.enable = true;
        trim-trailing-whitespace.enable = true;
        check-merge-conflicts.enable = true;
        qmlformat = {
          enable = true;
          name = "qmlformat";
          entry = "${nixpkgs.legacyPackages.x86_64-linux.kdePackages.qtdeclarative}/bin/qmlformat --inplace";
          types = ["file"];
          files = "\\.qml$";
        };
        niri-validate = {
          enable = true;
          name = "niri-validate";
          entry = "${nixpkgs.legacyPackages.x86_64-linux.niri}/bin/niri validate --config";
          types = ["file"];
          files = "\\.kdl$";
        };
      };
    };

    formatter.x86_64-linux = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      config = self.checks.x86_64-linux.pre-commit-check.config;
      inherit (config) package configFile;
    in
      pkgs.writeShellScriptBin "pre-commit-run" ''
        ${pkgs.lib.getExe package} run --all-files --config ${configFile}
      '';

    nixosConfigurations.xps = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit pixie-sddm nixvim;};
      modules = [
        ./hosts/xps/configuration.nix
        impermanence.nixosModules.impermanence
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        nixos-hardware.nixosModules.dell-xps-15-9530
        nixos-hardware.nixosModules.dell-xps-15-9530-nvidia
        nur.modules.nixos.default
        sops-nix.nixosModules.sops
        ./modules/sops.nix
        ./modules/core.nix
        ./modules/tpm.nix
        ./modules/clipboard/xclip.nix
        ./modules/clipboard/wclip.nix
        ./modules/desktop/niri.nix
        ./modules/audio.nix
        ./modules/bluetooth.nix
        ./modules/localization/frenglish.nix
        ./modules/programs/programs.nix
        ./modules/users/cookiegigi.nix
        ./modules/home
        ./modules/networks/wifi-home.nix
      ];
    };

    nixosConfigurations.xps-iso = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # 1. iso base
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        # 2. disko config
        ./hosts/xps/disko.nix
        # 3. disko module (need for disko.nix to work)
        disko.nixosModules.disko
        # 4. overrides (new file!)
        ./modules/iso.nix
      ];
    };

    packages.x86_64-linux = {
      disko = disko.packages.x86_64-linux.disko;
    };

    devShells.x86_64-linux.default = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      inherit (self.checks.x86_64-linux.pre-commit-check) shellHook enabledPackages;

      # Project-specific Neovim with qmlls for QML development in this repo
      projectNvim = nixvim.legacyPackages.x86_64-linux.makeNixvim {
        imports = [
          ./modules/home/cookiegigi/programs/nixvim/base.nix
        ];
        plugins = {
          lsp.servers.qmlls = {
            enable = true;
            package = pkgs.kdePackages.qttools;
          };
          conform-nvim.settings.formatters_by_ft.qml = ["qmlformat"];
        };
      };
    in
      pkgs.mkShell {
        shellHook = ''
          # Guard against global core.hooksPath which breaks pre-commit hook installation.
          # git-hooks.nix only unsets the local config; a global setting still blocks it.
          _global_hooksPath="$(${pkgs.git}/bin/git config --global core.hooksPath 2>/dev/null || true)"
          if [ -n "$_global_hooksPath" ]; then
            echo ""
            echo "WARNING: core.hooksPath is set globally ('$_global_hooksPath')."
            echo "This prevents pre-commit hooks from being installed by the Nix devShell."
            echo "Remove it with: git config --global --unset-all core.hooksPath"
            echo ""
          fi
          unset _global_hooksPath

          ${shellHook}
        '';
        buildInputs =
          enabledPackages
          ++ (with pkgs; [
            git
            sops
            age
            kdePackages.qtdeclarative
            projectNvim
          ]);
      };

    apps.x86_64-linux.edit-secrets = {
      type = "app";
      program = let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in
        toString (
          pkgs.writeShellScript "sops-edit-secrets" ''
            export SOPS_AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-/persist/var/lib/sops-nix/key.txt}"
            exec ${pkgs.sops}/bin/sops "''${1:-secrets/secrets.yaml}"
          ''
        );
    };
  };
}
