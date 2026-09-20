{
  networking.firewall = {
    # Home Assistant uses host networking for discovery, but HTTP ingress is
    # limited to Caddy's fixed proxy address rather than exposed to the LAN.
    extraCommands = ''
      iptables -A nixos-fw -s 10.89.100.2 -p tcp --dport 8123 -j ACCEPT
    '';
    # mDNS and SSDP discovery on the host network.
    allowedUDPPorts = [1900 5353];
  };
}
