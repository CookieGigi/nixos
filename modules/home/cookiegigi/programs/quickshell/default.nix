{pkgs, ...}: {
  home.packages = with pkgs; [
    quickshell
  ];

  # Symlink quickshell QML config into ~/.config/quickshell/
  # The directory name "bar" allows running it with `qs -c bar`.
  xdg.configFile."quickshell/bar/shell.qml".source = ./shell.qml;
  xdg.configFile."quickshell/bar/Bar.qml".source = ./Bar.qml;
  xdg.configFile."quickshell/bar/ClockWidget.qml".source = ./ClockWidget.qml;
  xdg.configFile."quickshell/bar/Time.qml".source = ./Time.qml;
  xdg.configFile."quickshell/bar/VolumeWidget.qml".source = ./VolumeWidget.qml;
}
