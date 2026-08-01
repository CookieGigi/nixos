_: {
  # ===========================================================================
  # Local DNS: resolve cookiegigi.com subdomains to the server's LAN IP
  # ===========================================================================
  # This lets internal clients reach services by subdomain without exposing
  # internal IPs on public DNS (Cloudflare). All *.cookiegigi.com resolves to
  # the server at 192.168.1.49.

  services.dnsmasq = {
    enable = true;
    settings = {
      # Listen only on loopback and the LAN IP
      listen-address = ["127.0.0.1" "192.168.1.49"];

      # Forward non-local queries to Cloudflare
      server = ["1.1.1.1" "1.0.0.1"];

      # Resolve all cookiegigi.com subdomains to the server
      address = "/cookiegigi.com/192.168.1.49";

      # Don't read /etc/hosts or /etc/resolv.conf
      no-hosts = true;
      no-resolv = true;

      # Cache size
      cache-size = 1000;

      # Log queries (optional, useful for debugging)
      log-queries = true;
      log-facility = "-";
    };
  };

  # Open DNS port for the LAN only
  networking.firewall = {
    allowedUDPPorts = [53];
    extraCommands = ''
      iptables -A nixos-fw -p udp --dport 53 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 53 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p udp --dport 53 -j nixos-fw-refuse
      iptables -A nixos-fw -p tcp --dport 53 -j nixos-fw-refuse
    '';
  };

  # Use dnsmasq as the server's own resolver
  networking.nameservers = ["127.0.0.1"];

  # Persist dnsmasq lease file
  environment.persistence."/persist".directories = [
    "/var/lib/dnsmasq"
  ];
}
