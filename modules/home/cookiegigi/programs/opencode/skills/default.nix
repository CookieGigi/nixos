{pkgs, ...}: let
  githooksFlake = import ./githooks-flake.nix {inherit pkgs;};
in {
  githooks-flake = githooksFlake;
}
