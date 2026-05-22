{
  config,
  pkgs,
  ...
}: {
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Garbage collection
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 30d";

  # nix store optimization
  nix.settings.auto-optimise-store = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # SSH
  programs.ssh.startAgent = true;
  services.gnome.gcr-ssh-agent.enable = false;

  # UPower for battery monitoring
  services.upower.enable = true;

  # NIX flags
  nix.settings.experimental-features = ["nix-command" "flakes"];

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
