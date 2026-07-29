_: {
  # Load the proprietary NVIDIA kernel module and driver stack.
  # Required even on a headless server for CUDA / NVENC / AI inference.
  services.xserver.videoDrivers = ["nvidia"];
  services.xserver.enable = false;

  hardware.nvidia = {
    # Required for proprietary driver initialization.
    modesetting.enable = true;

    # Open-source NVIDIA kernel modules — supported on Ampere GA102 / RTX 3080 Ti.
    open = true;

    # Provide nvidia-smi, nvidia-settings binaries.
    nvidiaSettings = true;
  };

  # Enable NVIDIA Container Toolkit for GPU passthrough to Podman containers.
  hardware.nvidia-container-toolkit.enable = true;
}
