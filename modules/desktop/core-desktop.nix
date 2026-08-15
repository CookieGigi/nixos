{
  # UPower for battery monitoring
  services.upower.enable = true;

  # NetworkManager for desktop networking
  networking = {
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };
    nameservers = ["192.168.1.49" "1.1.1.1" "9.9.9.9"];
    dhcpcd.extraConfig = ''
      nohook resolv.conf
    '';
    hosts = {
      "192.168.1.49" = ["zot.cookiegigi.com"];
    };
  };
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = ["192.168.1.49"];
      FallbackDNS = ["1.1.1.1" "9.9.9.9"];
    };
  };

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
