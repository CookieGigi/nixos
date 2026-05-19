{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the XFCE Desktop Environment.
  # Display manager (SDDM) is managed in modules/desktop/niri.nix.
  services.xserver.desktopManager.xfce.enable = true;

  # Persist
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/home/cookiegigi/.config/xfce4/xfconf/"
      "/home/cookiegigi/.config/xfce4/panel/"
    ];
  };
}
