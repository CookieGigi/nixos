# Global reverse proxy settings.
# If you use a different domain or ACME email, override them in the
# host-specific configuration (hosts/server/configuration.nix).
_: {
  services.reverseProxy = {
    enable = true;
    domain = "cookiegigi.com";
    acmeEmail = "cookiegigi@cookiegigi.com"; # <-- Set your real email before deploying
    dnsProvider = "cloudflare"; # DNS-01 challenge (no port forwarding needed)
  };
}
