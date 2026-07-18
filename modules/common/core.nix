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

  # Allow proprietary Nvidia drivers
  nixpkgs.config.allowUnfree = true;

  # Enable OpenGL/Vulkan (64-bit only — 32-bit is desktop/gaming-specific)
  hardware.graphics = {
    enable = true;
  };

  # Impermanence base mount
  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/ssh"
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
    ];
  };
}
