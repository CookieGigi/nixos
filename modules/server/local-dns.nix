{
  lib,
  config,
  ...
}: {
  # ===========================================================================
  # AdGuard Home: local DNS with ad-blocking, DoH/DoT, and local rewrites
  # ===========================================================================
  # Replaces dnsmasq. Provides DNS-level ad/tracker blocking, encrypted
  # upstream queries (DoH/DoT to Cloudflare), and local rewrites so
  # *.cookiegigi.com resolves to the server LAN IP.

  services = {
    # Disable the old dnsmasq service
    dnsmasq.enable = lib.mkForce false;

    adguardhome = {
      enable = true;
      settings = {
        # Web UI bound to localhost only — exposed via reverse proxy
        http.address = "127.0.0.1:3000";

        dns = {
          # Listen on loopback and LAN IP
          bind_hosts = ["127.0.0.1" "192.168.1.49"];
          port = 53;

          # Parallel upstream queries for speed
          upstream_mode = "parallel";

          # Encrypted upstream: DoH + DoT to Cloudflare
          upstream_dns = [
            "https://1.1.1.1/dns-query"
            "https://1.0.0.1/dns-query"
            "tls://1.1.1.1"
            "tls://1.0.0.1"
          ];

          # Plain UDP bootstrap to resolve the DoH hostnames
          bootstrap_dns = ["1.1.1.1" "1.0.0.1"];

          # Local rewrites: all cookiegigi.com subdomains → server
          rewrites = [
            {
              domain = "*.cookiegigi.com";
              answer = "192.168.1.49";
            }
            {
              domain = "cookiegigi.com";
              answer = "192.168.1.49";
            }
          ];
        };

        filtering = {
          protection_enabled = true;
          filtering_enabled = true;
        };

        filters = [
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
            name = "AdGuard DNS filter";
            id = 1;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
            name = "AdAway Default Blocklist";
            id = 2;
          }
        ];
      };
    };

    # Reverse proxy: dns.cookiegigi.com → AdGuard web UI
    reverseProxy.upstreams = lib.mkIf config.services.reverseProxy.enable [
      {
        subdomain = "dns";
        port = 3000;
        systemdService = "adguardhome";
      }
    ];
  };

  # ------------------------------------------------------------------
  # Firewall: port 53 only for the LAN subnet
  # ------------------------------------------------------------------
  networking.firewall = {
    allowedUDPPorts = [53];
    extraCommands = ''
      iptables -A nixos-fw -p udp --dport 53 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 53 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p udp --dport 53 -j nixos-fw-refuse
      iptables -A nixos-fw -p tcp --dport 53 -j nixos-fw-refuse
    '';
  };

  # Server uses AdGuard locally
  networking.nameservers = ["127.0.0.1"];

  # Persist AdGuard data and filters
  environment.persistence."/persist".directories = [
    "/var/lib/AdGuardHome"
  ];
}
