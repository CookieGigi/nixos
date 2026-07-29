{pkgs, ...}: {
  # Rootless Podman with Docker socket compatibility
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
  };

  # Enable NVIDIA Container Toolkit for GPU passthrough to Podman containers.
  # xps already has the NVIDIA driver via nixos-hardware; this adds the CDI
  # runtime configuration so containers can request `nvidia.com/gpu=all`.
  hardware.nvidia-container-toolkit.enable = true;

  environment = {
    systemPackages = with pkgs; [
      podman-compose
    ];

    # Persist container storage (images, layers) across reboots on NVMe.
    persistence."/persist".directories = [
      "/var/lib/containers"
    ];
  };
}
