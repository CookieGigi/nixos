{pkgs, ...}: {
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.blueman.enable = false;

  environment.systemPackages = with pkgs; [
    bluetuith
  ];

  environment.persistence."/persist".directories = [
    "/var/lib/bluetooth"
  ];
}
