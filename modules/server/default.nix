{
  imports = [
    ../common
    ./core-server.nix
    ./security.nix
    ./containers.nix
    ./nvidia.nix
    ./opencode-serve.nix
    ./opencode-serve/reverse-proxy.nix
    ./storage-layout.nix
    ./reverse-proxy
    ./local-dns.nix
    ./containers/immich
    ./containers/llama
    ./containers/proton-drive
  ];
}
