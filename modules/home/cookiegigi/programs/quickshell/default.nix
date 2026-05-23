{pkgs, ...}: {
  home.packages = with pkgs; [
    quickshell

    # Script to trigger the quickshell app launcher from a hotkey.
    (writeShellScriptBin "show-app-launcher" ''
      touch /tmp/quickshell-launcher
    '')
  ];

  # Symlink quickshell QML config into ~/.config/quickshell/
  # The directory name "bar" allows running it with `qs -c bar`.
  xdg = {
    configFile = {
      "quickshell/bar/shell.qml".source = ./shell.qml;
      "quickshell/bar/Bar.qml".source = ./Bar.qml;
      "quickshell/bar/Time.qml".source = ./Time.qml;
      "quickshell/bar/BatteryWidget.qml".source = ./BatteryWidget.qml;
      "quickshell/bar/VolumeWidget.qml".source = ./VolumeWidget.qml;
      "quickshell/bar/PowerButton.qml".source = ./PowerButton.qml;
      "quickshell/bar/AppLauncher.qml".source = ./AppLauncher.qml;
      "quickshell/bar/PowerMenu.qml".source = ./PowerMenu.qml;
    };
  };
}
