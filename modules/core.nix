{
  config,
  pkgs,
  ...
}: {
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable networking
  networking.networkmanager.enable = true;

  # SSH
  programs.ssh.startAgent = true;
  services.gnome.gcr-ssh-agent.enable = false;

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
