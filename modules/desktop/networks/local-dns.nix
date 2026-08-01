{pkgs, ...}: {
  # ===========================================================================
  # Desktop DNS: use the server's AdGuard Home (192.168.1.49) exclusively
  # ===========================================================================
  # AdGuard handles everything:
  #   - *.cookiegigi.com → 192.168.1.49 (local rewrites)
  #   - Everything else → Cloudflare DoH/DoT
  # No fallback needed — adding 1.1.1.1 causes NXDOMAIN for internal domains.

  services.resolved = {
    enable = true;
    settings.Resolve.DNS = "192.168.1.49";
  };

  networking.networkmanager.dns = "systemd-resolved";

  # Add dig for DNS debugging
  environment.systemPackages = [pkgs.bind];
}
