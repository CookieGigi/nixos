{
  config,
  pkgs,
  ...
}: {
  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  programs.waybar.enable = true;
  programs.fuzzel.enable = true;
  services.mako.enable = true;
  programs.swaylock.enable = true;
  services.swayidle.enable = true;

  home.packages = with pkgs; [
    brightnessctl
    playerctl
    swaybg
    xwayland-satellite
  ];
}
