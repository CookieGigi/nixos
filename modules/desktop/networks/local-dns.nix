_: {
  # ===========================================================================
  # Desktop DNS: use the server's AdGuard Home (192.168.1.49) as primary
  # ===========================================================================
  # Falls back to Cloudflare (1.1.1.1) if the server is unreachable.
  # Uses systemd-resolved (works cleanly with NetworkManager).

  # Enable systemd-resolved as the local DNS stub
  services.resolved.enable = true;

  # Set upstream nameservers: AdGuard Home first, Cloudflare fallback
  networking.nameservers = [
    "192.168.1.49"
    "1.1.1.1"
  ];

  # Tell NetworkManager to use systemd-resolved for DNS
  networking.networkmanager.dns = "systemd-resolved";
}
