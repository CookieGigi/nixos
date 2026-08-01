{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.reverseProxy;

  upstreamServices = lib.filter (u: u.systemdService != null) cfg.upstreams;

  # Caddy with Cloudflare DNS plugin when DNS-01 is configured.
  caddyPkg =
    if cfg.dnsProvider == "cloudflare"
    then
      pkgs.caddy.withPlugins {
        plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
        hash = "sha256-7GoH8YLCoPmPExQxoga2FHB58zQDoZVf1BBwkVi0SsQ=";
      }
    else pkgs.caddy;

  # Build a Caddyfile. When using DNS-01, inject a global block.
  caddyfileText =
    lib.optionalString (cfg.dnsProvider == "cloudflare") ''
      {
        acme_dns cloudflare {env.CF_API_TOKEN}
      }
    ''
    + lib.concatStringsSep "\n" (map
      (upstream: ''
        ${upstream.subdomain}.${cfg.domain} {
          reverse_proxy localhost:${toString upstream.port}
          ${upstream.extraCaddyConfig}
        }
      '')
      cfg.upstreams);

  caddyfile = pkgs.writeText "Caddyfile" caddyfileText;
in
  lib.mkIf cfg.enable {
    # ------------------------------------------------------------------
    # Caddy: reverse proxy + automatic HTTPS via ACME
    # ------------------------------------------------------------------
    services.caddy = {
      enable = true;
      email = cfg.acmeEmail;
      package = caddyPkg;
      configFile = "${caddyfile}";
    };

    # ------------------------------------------------------------------
    # Cloudflare API token for DNS-01 challenge + systemd ordering
    # ------------------------------------------------------------------
    systemd.services.caddy =
      lib.optionalAttrs (cfg.dnsProvider == "cloudflare") {
        serviceConfig = {
          EnvironmentFile = config.sops.secrets."cf-api-token".path;
        };
      }
      // lib.optionalAttrs (upstreamServices != []) {
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
