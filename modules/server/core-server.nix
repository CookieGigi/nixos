_: {
  # Server networking: systemd-networkd instead of NetworkManager
  networking = {
    networkmanager.enable = false;
    useNetworkd = true;
    nameservers = ["127.0.0.1" "1.1.1.1"];
    hosts = {
      "140.82.121.34" = ["ghcr.io"];
      "185.199.108.154" = ["pkg-containers.githubusercontent.com"];
      "127.0.0.1" = ["zot.cookiegigi.com"];
    };
  };

  services.resolved.enable = false;
}
