{pkgs, ...}: {
  # Bootloader.
  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # Nix settings
  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];
    };
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # UPower for battery monitoring
  services.upower.enable = true;

  # persist
  fileSystems."/persist".neededForBoot = true;

  # Allow proprietary Nvidia drivers
  nixpkgs.config.allowUnfree = true;

  # Enable OpenGL/Vulkan (32-bit support required for Proton/Wine games)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/etc/ssh"
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
    ];
  };
}
