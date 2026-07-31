{
  imports = [
    ../common
    ./core-server.nix
    ./security.nix
    ./containers.nix
    ./nvidia.nix
    ./llama-container.nix
    ./opencode-serve.nix
    ./storage-layout.nix
    ./immich.nix
    ./proton-drive.nix
  ];
}
