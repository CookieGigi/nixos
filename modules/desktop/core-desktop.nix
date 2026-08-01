{
  # UPower for battery monitoring
  services.upower.enable = true;

  # NetworkManager for desktop networking
  networking.networkmanager.enable = true;

  # Enable OpenGL/Vulkan (64-bit only — 32-bit is desktop/gaming-specific)
  hardware.graphics = {
    enable = true;
  };
  # 32-bit OpenGL/Vulkan support (required for Proton/Wine gaming)
  hardware.graphics.enable32Bit = true;

  # Add user to networkmanager group
  users.users.cookiegigi.extraGroups = ["networkmanager"];

  # Persist NetworkManager connections
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
    ];
  };
}
