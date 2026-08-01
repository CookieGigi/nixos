_: {
  # ===========================================================================
  # Desktop DNS: use the server's AdGuard Home (192.168.1.49) as primary
  # ===========================================================================
  # Falls back to Cloudflare (1.1.1.1) if the server is unreachable.
  # Applied to all NetworkManager connections.

  networking.networkmanager.connectionConfig = {
    "ipv4.dns" = "192.168.1.49;1.1.1.1;";
    "ipv4.ignore-auto-dns" = "true";
  };
}
