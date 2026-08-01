{
  imports = [
    ../common
    ./sops.nix
    ./core-server.nix
    ./security.nix
    ./containers.nix
    ./nvidia.nix
    ./storage-layout.nix
    ./reverse-proxy
    ./local-dns.nix
    ./containers/immich
    ./containers/llama
    ./containers/proton-drive
  ];
}
