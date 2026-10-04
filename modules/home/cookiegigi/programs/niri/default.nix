{
  lib,
  pkgs,
  ...
}: let
  # Locks only while running on battery; a no-op when plugged into AC.
  # Falls back to locking when no battery status can be read.
  idleLock = pkgs.writeShellScript "idle-lock" ''
    set -uo pipefail

    lock_on_battery() {
      local found=0 status
      for status in /sys/class/power_supply/BAT*/status; do
        [ -r "$status" ] || continue
        found=1
        [ "$(cat "$status")" = "Discharging" ] && return 0
      done
      [ "$found" -eq 0 ]
    }

    if lock_on_battery; then
      exec ${pkgs.swaylock}/bin/swaylock -f
    fi
  '';
in {
  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  programs = {
    swaylock.enable = true;
  };

  services = {
    mako.enable = true;
    swayidle = {
      enable = true;
      timeouts = [
        {
          timeout = 300;
          command = lib.getExe' idleLock "idle-lock";
        }
      ];
      events.before-sleep = "${pkgs.swaylock}/bin/swaylock -f";
    };
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
