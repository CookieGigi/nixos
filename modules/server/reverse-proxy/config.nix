# Global reverse proxy settings.
# If you use a different domain or ACME email, override them in the
# host-specific configuration (hosts/server/configuration.nix).
_: {
  services.reverseProxy = {
    enable = true;
    domain = "cookiegigi.com";
    acmeEmail = "CHANGEME@example.com"; # <-- Set your real email before deploying
  };
}
