{
  networking.firewall = {
    allowedTCPPorts = [8123];
    # mDNS and SSDP discovery on the host network.
    allowedUDPPorts = [1900 5353];
  };
}
