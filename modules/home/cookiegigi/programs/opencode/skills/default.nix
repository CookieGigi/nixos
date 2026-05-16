{pkgs, ...}: {
  impermanence = import ./impermanence.nix {inherit pkgs;};
  nix-basics = import ./nix-basics.nix {inherit pkgs;};
  nixos-rebuild = import ./nixos-rebuild.nix {inherit pkgs;};
  nix-config-modularity = import ./nix-config-modularity.nix {inherit pkgs;};
}
