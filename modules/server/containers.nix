{pkgs, ...}: {
  # Rootless Podman with Docker socket compatibility
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
  };

  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
