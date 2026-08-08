_: {
  # Rootless Podman with Docker socket compatibility
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  environment = {
    # Persist container storage (images, layers) across reboots on NVMe.
    persistence."/persist".directories = [
      "/var/lib/containers"
    ];
  };
}
