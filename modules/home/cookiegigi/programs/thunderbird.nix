_: {
  programs.thunderbird = {
    enable = true;

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DontCheckDefaultBrowser = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
    };

    profiles."cookiegigi" = {
      isDefault = true;
      settings = {
        # Respect the dark GTK/Wayland theme.
        "ui.systemUsesDarkTheme" = 1;
        "mailnews.wraplength" = 80;
      };
    };
  };

  home.persistence."/persist" = {
    directories = [
      ".thunderbird"
    ];
  };
}
