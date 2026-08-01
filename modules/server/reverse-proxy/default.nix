{lib, ...}: {
  imports = [
    ./caddy.nix
    ./config.nix
  ];

  options.services.reverseProxy = {
    enable = lib.mkEnableOption "reverse proxy for cookiegigi.com";

    domain = lib.mkOption {
      type = lib.types.str;
      default = "cookiegigi.com";
      description = "Base domain. Every upstream gets a subdomain under this domain.";
    };

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      example = "admin@cookiegigi.com";
      description = "Email address for Let's Encrypt ACME account registration.";
    };

    dnsProvider = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["cloudflare"]);
      default = null;
      description = ''
        DNS provider for ACME DNS-01 challenge. When set, Caddy uses the
        DNS-01 challenge instead of HTTP-01 or TLS-ALPN-01. This allows
        certificate issuance without exposing ports 80/443 to the internet.

        - `null`: Use HTTP-01 / TLS-ALPN-01 (requires port forwarding).
        - `cloudflare`: Use Cloudflare DNS-01 (requires `CF_API_TOKEN` secret).
      '';
    };

    # ---------------------------------------------------------------------------
    # List-based upstreams — no hardcoded services.
    #
    # Instead of fixed options like `services.immich.enable`, each backend is
    # declared as an entry in this list. This makes the module trivially
    # extensible: add a new service by appending another element.
    #
    # Each upstream exposes a single subdomain → localhost port mapping.
    # Additional Caddy directives can be injected per upstream via
    # `extraCaddyConfig` (rate limiting, headers, redirects, etc.).
    # ---------------------------------------------------------------------------
    upstreams = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          subdomain = lib.mkOption {
            type = lib.types.str;
            example = "photos";
            description = "Subdomain to route. Resulting virtual host: <subdomain>.<domain>.";
          };

          port = lib.mkOption {
            type = lib.types.port;
            example = 2283;
            description = "Local TCP port the backend service listens on.";
          };

          extraCaddyConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
            example = lib.literalExpression ''
              header / Strict-Transport-Security "max-age=31536000; includeSubDomains"
            '';
            description = "Additional Caddy site directives appended after the reverse_proxy block.";
          };

          systemdService = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "llama-cpp";
            description = ''
              Optional systemd unit name that must be up before Caddy starts.
              If set, Caddy's `after`/`wants` is wired to this unit. Leave
              `null` if you don't need ordering guarantees (Caddy will happily
              serve 502 until the backend comes up).
            '';
          };
        };
      });
      default = [];
      example = lib.literalExpression ''
        [
          { subdomain = "photos"; port = 2283; }
          { subdomain = "ai"; port = 8080; systemdService = "llama-cpp"; }
        ]
      '';
      description = ''
        List of backend services to expose through the reverse proxy.
        Each service module typically appends its own upstream here via
        `config.services.reverseProxy.upstreams = [ { ... } ]`.
      '';
    };
  };
}
