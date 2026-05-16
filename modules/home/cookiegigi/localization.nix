{...}: {
  # User-level locale settings (system-level timezone, X11 keymap, and console keymap
  # remain in modules/localization/frenglish.nix)
  home.language.base = "en_US.UTF-8";
  home.language.address = "fr_FR.UTF-8";
  home.language.measurement = "fr_FR.UTF-8";
  home.language.monetary = "fr_FR.UTF-8";
  home.language.name = "fr_FR.UTF-8";
  home.language.numeric = "fr_FR.UTF-8";
  home.language.paper = "fr_FR.UTF-8";
  home.language.telephone = "fr_FR.UTF-8";
  home.language.time = "fr_FR.UTF-8";

  home.sessionVariables = {
    LC_IDENTIFICATION = "fr_FR.UTF-8";
  };
}
