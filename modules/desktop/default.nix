{
  imports = [
    ../common
    ./core-desktop.nix
    ./audio.nix
    ./bluetooth.nix
    ./clipboard/xclip.nix
    ./clipboard/wclip.nix
    ./networks/wifi-home.nix
    ./networks/local-dns.nix
    ./steam.nix
    ./nix-ld.nix
    ./containers.nix
  ];
}
