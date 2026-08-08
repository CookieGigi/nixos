{
  imports = [
    ../common
    ./sops.nix
    ./core-server.nix
    ./security.nix
    ./nvidia.nix
    ./storage-layout.nix
    ./containers/immich
    ./containers/llama
    ./containers/proton-drive
    ./containers/fileflows
    ./containers/blocky
    ./containers/caddy
  ];
}
