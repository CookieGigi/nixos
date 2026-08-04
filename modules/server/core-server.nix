_: {
  # Server networking: systemd-networkd instead of NetworkManager
  networking = {
    networkmanager.enable = false;
    useNetworkd = true;
    nameservers = ["127.0.0.1"];
  };

  services.resolved.enable = false;
}
