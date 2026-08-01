{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.reverseProxy;

  upstreamServices = lib.filter (u: u.systemdService != null) cfg.upstreams;

  # Build a Caddyfile with one site block per upstream.
  caddyfile = pkgs.writeText "Caddyfile" (lib.concatStringsSep "\n" (map
    (upstream: ''
      ${upstream.subdomain}.${cfg.domain} {
        reverse_proxy localhost:${toString upstream.port}
        ${upstream.extraCaddyConfig}
      }
    '')
    cfg.upstreams));
in
  lib.mkIf cfg.enable {
    # ------------------------------------------------------------------
    # Caddy: reverse proxy + automatic HTTPS via ACME
    # ------------------------------------------------------------------
    services.caddy = {
      enable = true;
      email = cfg.acmeEmail;
      configFile = "${caddyfile}";
    };

    # ------------------------------------------------------------------
    # Systemd ordering: wait for upstream systemd units if declared
    # ------------------------------------------------------------------
    systemd.services.caddy = lib.optionalAttrs (upstreamServices != []) {
      after = map (u: "${u.systemdService}.service") upstreamServices;
      wants = map (u: "${u.systemdService}.service") upstreamServices;
    };

    # ------------------------------------------------------------------
    # Persistence: certificates and Caddy state survive reboots
    # ------------------------------------------------------------------
    environment.persistence."/persist".directories = [
      "/var/lib/caddy"
    ];
  }
