{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the XFCE Desktop Environment.
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;

  # Persist
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/home/cookiegigi/.config/xfce4/xfconf/"
    ];
  };
}
