{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
    };
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    ...
  }: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    nixosConfigurations.xps = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [./hosts/xps/configuration.nix disko.nixosModules.disko];
    };

    nixosConfigurations.xps-iso = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # 1. iso base
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        # 2. your real config (bring disko with it!)
        ./hosts/xps/configuration.nix
        # 3. disko module (need for disko.nix to work)
        disko.nixosModules.disko
        # 4. overrides (new file!)
        ./hosts/xps/iso.nix
      ];
    };

    packages.x86_64-linux.disko = disko.packages.x86_64-linux.disko;
  };
}
