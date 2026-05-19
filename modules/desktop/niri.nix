{pkgs, ...}: let
  catppuccin-sddm-theme = pkgs.catppuccin-sddm.override {
    flavor = "macchiato";
    accent = "teal";
    background = "/home/cookiegigi/Pictures/Wallpapers/voyager-4.jpg";
  };
in {
  programs.niri.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "${catppuccin-sddm-theme}/share/sddm/themes/catppuccin-macchiato-teal";
  };
}
