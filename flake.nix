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
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    impermanence,
    home-manager,
    nixos-hardware,
    nur,
    ...
  }: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    nixosConfigurations.xps = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/xps/configuration.nix
        impermanence.nixosModules.impermanence
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        nixos-hardware.nixosModules.dell-xps-15-9530
        nixos-hardware.nixosModules.dell-xps-15-9530-nvidia
        nur.modules.nixos.default
        ./modules/core.nix
        ./modules/clipboard/xclip.nix
        ./modules/desktop/xfce.nix
        ./modules/audio.nix
        ./modules/localization/frenglish.nix
        ./modules/programs/programs.nix
        ./modules/users/cookiegigi.nix
        ./modules/home
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

    packages.x86_64-linux.disko = disko.packages.x86_64-linux.disko;
  };
}
