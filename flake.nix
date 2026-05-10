{
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
};

outputs = { self, nixpkgs, ... }: {
  nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ ./hosts/xps/configuration.nix ];
  };
};
}
