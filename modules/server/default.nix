{
  imports = [
    ../common
    ./core-server.nix
    ./security.nix
    ./containers.nix
    ./nvidia.nix
    ./opencode-serve.nix
    ./storage-layout.nix
    ./reverse-proxy
    ./containers/immich
    ./containers/llama
    ./containers/proton-drive
  ];
}
