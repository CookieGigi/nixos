{pkgs, ...}: {
  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  programs = {
    swaylock.enable = true;
  };

  services = {
    mako.enable = true;
    swayidle.enable = true;
  };

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    brightnessctl
    playerctl
    swaybg
    xwayland-satellite
    grim
    slurp
    libnotify

    (pkgs.writeShellScriptBin "screenshot-region" ''
      set -euo pipefail
      DIR="$HOME/Pictures/Screenshots"
      mkdir -p "$DIR"
      FILE="$DIR/Screenshot from $(date "+%Y-%m-%d %H-%M-%S").png"
      grim -g "$(slurp)" "$FILE"
      echo -n "$FILE" | wl-copy
      notify-send "Screenshot copied" "Path saved to clipboard: $FILE"
    '')

    (pkgs.writeShellScriptBin "screenshot-full" ''
      set -euo pipefail
      DIR="$HOME/Pictures/Screenshots"
      mkdir -p "$DIR"
      FILE="$DIR/Screenshot from $(date "+%Y-%m-%d %H-%M-%S").png"
      grim "$FILE"
      echo -n "$FILE" | wl-copy
      notify-send "Screenshot copied" "Path saved to clipboard: $FILE"
    '')
  ];
}
