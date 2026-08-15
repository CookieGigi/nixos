{pkgs, ...}: {
  systemd.tmpfiles.rules = [
    "C /etc/caddy/Caddyfile 0644 root root - ${pkgs.writeText "Caddyfile" ''
      {
      	acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      }

      *.cookiegigi.com {
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
      }
    ''}"
  ];
}
