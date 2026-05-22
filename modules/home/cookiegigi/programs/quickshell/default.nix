{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs;
    [
      quickshell

      # Power menu script used by the quickshell bar
      (writeShellScriptBin "power-menu" ''
        choice=$(printf "Shutdown\nReboot\nSuspend\nLogout\nCancel" | ${fuzzel}/bin/fuzzel --dmenu --prompt "Power: " --width 20)
        case "$choice" in
          Shutdown) systemctl poweroff ;;
          Reboot) systemctl reboot ;;
          Suspend) systemctl suspend ;;
          Logout) ${niri}/bin/niri msg action quit ;;
        esac
      '')
    ]
    ++ lib.optionals config.programs.waybar.enable [pkgs.fuzzel];

  # Symlink quickshell QML config into ~/.config/quickshell/
  # The directory name "bar" allows running it with `qs -c bar`.
  xdg.configFile."quickshell/bar/shell.qml".source = ./shell.qml;
  xdg.configFile."quickshell/bar/Bar.qml".source = ./Bar.qml;
  xdg.configFile."quickshell/bar/Time.qml".source = ./Time.qml;
  xdg.configFile."quickshell/bar/BatteryWidget.qml".source = ./BatteryWidget.qml;
  xdg.configFile."quickshell/bar/PowerButton.qml".source = ./PowerButton.qml;
}
