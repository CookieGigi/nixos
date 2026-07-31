{pkgs, ...}: {
  # Server networking: systemd-networkd instead of NetworkManager
  networking.networkmanager.enable = false;
  networking.useNetworkd = true;

  environment.systemPackages = with pkgs; [
    unzip
  ];
}
