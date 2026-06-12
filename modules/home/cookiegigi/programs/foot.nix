{
  pkgs,
  lib,
  ...
}: let
  ini = pkgs.formats.ini {listsAsDuplicateKeys = true;};
  settings = {
    main = {
      font = "JetBrains Mono:size=12";
    };
    "colors-dark" = {
      alpha = 0.8;
    };
    cursor = {
      style = "beam";
      blink = "yes";
      blink-rate = 500;
      beam-thickness = 1.5;
    };
    mouse = {
      hide-when-typing = "yes";
    };
    url = {
      launch = "xdg-open \${url}";
      osc8-underline = "url-mode";
    };
  };
in {
  programs.foot = {
    enable = true;
    settings = {}; # Disable auto-generation so we can prepend `include`
  };

  xdg.configFile."foot/foot.ini".text = lib.concatStrings [
    "include = ${pkgs.foot.themes}/share/foot/themes/catppuccin-macchiato\n\n"
    (lib.readFile (ini.generate "foot-base.ini" settings))
  ];

  # ── Font dependency ────────────────────────────────────────────
  home.packages = [
    pkgs.jetbrains-mono
  ];

  # ── Persistence ────────────────────────────────────────────────
  home.persistence."/persist" = {
    directories = [
      ".config/foot"
    ];
  };
}
