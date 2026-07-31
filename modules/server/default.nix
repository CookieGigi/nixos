{
  imports = [
    ../common
    ./core-server.nix
    ./security.nix
    ./containers.nix
    ./nvidia.nix
    ./opencode-serve.nix
    ./storage-layout.nix
    ./containers/immich
    ./containers/llama
    ./containers/proton-drive
  ];
}
