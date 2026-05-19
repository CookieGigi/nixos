{...}: {
  programs.niri.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/home/cookiegigi/.config/niri/"
      "/var/lib/sddm"
    ];
  };
}
