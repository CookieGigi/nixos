_: {
  # User-level locale settings (system-level timezone, X11 keymap, and console keymap
  # remain in modules/localization/frenglish.nix)
  home = {
    language = {
      base = "en_US.UTF-8";
      address = "fr_FR.UTF-8";
      measurement = "fr_FR.UTF-8";
      monetary = "fr_FR.UTF-8";
      name = "fr_FR.UTF-8";
      numeric = "fr_FR.UTF-8";
      paper = "fr_FR.UTF-8";
      telephone = "fr_FR.UTF-8";
      time = "fr_FR.UTF-8";
    };

    sessionVariables = {
      LC_IDENTIFICATION = "fr_FR.UTF-8";
    };
  };
}
