{
  imports = [
    ../common
    ./sops.nix
    ./core-desktop.nix
    ./audio.nix
    ./bluetooth.nix
    ./clipboard/wclip.nix
    ./networks/wifi-home.nix
    ./networks/local-dns.nix
    ./steam.nix
    ./nix-ld.nix
    ./ssh.nix
    ./niri.nix
  ];
}
