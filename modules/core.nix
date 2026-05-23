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
    };
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # SSH
  programs.ssh.startAgent = true;
  services.gnome.gcr-ssh-agent.enable = false;

  # UPower for battery monitoring
  services.upower.enable = true;

  # persist
  fileSystems."/persist".neededForBoot = true;

  # Allow proprietary Nvidia drivers
  nixpkgs.config.allowUnfree = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
    ];
  };
}
