{pkgs, ...}: {
  home.packages = with pkgs; [
    quickshell
  ];

  # Symlink quickshell QML config into ~/.config/quickshell/bar/
  # so it can be launched with `qs -c bar`.
  xdg = {
    configFile = {
      "quickshell/bar/shell.qml".source = ./shell.qml;
      "quickshell/bar/theme/Theme.qml".source = ./theme/Theme.qml;
      "quickshell/bar/services/Time.qml".source = ./services/Time.qml;
      "quickshell/bar/services/Visibilities.qml".source = ./services/Visibilities.qml;
      "quickshell/bar/components/Pill.qml".source = ./components/Pill.qml;
      "quickshell/bar/components/StyledText.qml".source = ./components/StyledText.qml;
      "quickshell/bar/components/Icon.qml".source = ./components/Icon.qml;
      "quickshell/bar/components/Percentage.qml".source = ./components/Percentage.qml;
      "quickshell/bar/components/Button.qml".source = ./components/Button.qml;
      "quickshell/bar/components/PopupBase.qml".source = ./components/PopupBase.qml;
      "quickshell/bar/components/PopupShell.qml".source = ./components/PopupShell.qml;
      "quickshell/bar/components/SelectionList.qml".source = ./components/SelectionList.qml;
      "quickshell/bar/widgets/ClockWidget.qml".source = ./widgets/ClockWidget.qml;
      "quickshell/bar/widgets/WindowTitleWidget.qml".source = ./widgets/WindowTitleWidget.qml;
      "quickshell/bar/widgets/VolumeWidget.qml".source = ./widgets/VolumeWidget.qml;
      "quickshell/bar/widgets/BatteryWidget.qml".source = ./widgets/BatteryWidget.qml;
      "quickshell/bar/widgets/NetworkWidget.qml".source = ./widgets/NetworkWidget.qml;
      "quickshell/bar/widgets/PowerWidget.qml".source = ./widgets/PowerWidget.qml;
      "quickshell/bar/widgets/MusicWidget.qml".source = ./widgets/MusicWidget.qml;
      "quickshell/bar/popups/AppLauncher.qml".source = ./popups/AppLauncher.qml;
      "quickshell/bar/popups/PowerMenu.qml".source = ./popups/PowerMenu.qml;
      "quickshell/bar/modules/Bar.qml".source = ./modules/Bar.qml;
    };
  };
}
