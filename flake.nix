{
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
};

outputs = { self, nixpkgs, ... }: {
  formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

  nixosConfigurations.xps = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ ./hosts/xps/configuration.nix ];
  };
};
}
