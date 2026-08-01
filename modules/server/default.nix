{
  imports = [
    ../common
    ./sops.nix
    ./core-server.nix
    ./security.nix
    ./containers.nix
    ./nvidia.nix
    ./storage-layout.nix
    ./containers/immich
    #    ./containers/llama
    #    ./containers/proton-drive
  ];
}
