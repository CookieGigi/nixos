{
  pkgs,
  config,
  ...
}: let
  # ── Catppuccin Macchiato Teal palette ─────────────────────────
  c = {
    base = "#24273a";
    mantle = "#1e2030";
    crust = "#181926";
    surface0 = "#363a4f";
    surface1 = "#494d64";
    surface2 = "#5b6078";
    overlay0 = "#6e738d";
    overlay1 = "#8087a2";
    overlay2 = "#939ab7";
    subtext0 = "#a5adcb";
    subtext1 = "#b8c0e0";
    text = "#cad3f5";
    lavender = "#b7bdf8";
    blue = "#8aadf4";
    sapphire = "#7dc4e4";
    sky = "#91d7e3";
    teal = "#8bd5ca";
    green = "#a6da95";
    yellow = "#eed49f";
    peach = "#f5a97f";
    maroon = "#ee99a0";
    red = "#ed8796";
    mauve = "#c6a0f6";
    pink = "#f5bde6";
    flamingo = "#f0c6c6";
    rosewater = "#f4dbd6";
  };
in {
  # ── GTK ────────────────────────────────────────────────────────
  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Macchiato-Teal";
      package = pkgs.catppuccin-gtk.override {
        variant = "macchiato";
        accents = ["teal"];
      };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "macchiato";
        accent = "teal";
      };
    };
    cursorTheme = {
      name = "catppuccin-macchiato-teal-cursors";
      package = pkgs.catppuccin-cursors;
      size = 24;
    };
    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
    gtk4.theme = config.gtk.theme;
  };

  # ── Qt / Kvantum ─────────────────────────────────────────────
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };

  home.packages = with pkgs; [
    catppuccin-kvantum
  ];

  # ── Fuzzel (app launcher) ────────────────────────────────────
  programs.fuzzel = {
    settings = {
      main = {
        width = 40;
        lines = 10;
        font = "JetBrainsMono Nerd Font:size=11";
      };
      colors = {
        background = "${c.base}f2";
        text = "${c.text}ff";
        match = "${c.teal}ff";
        selection = "${c.surface1}ff";
        selection-text = "${c.text}ff";
        selection-match = "${c.teal}ff";
        border = "${c.teal}ff";
      };
      border = {
        width = 2;
        radius = 12;
      };
    };
  };

  # ── Mako (notifications) ─────────────────────────────────────
  services.mako.settings = {
    background-color = "${c.base}ee";
    text-color = "${c.text}ff";
    border-color = "${c.teal}ff";
    border-size = 2;
    border-radius = 12;
    padding = "12,16";
    margin = "10,10,10,10";
    font = "JetBrains Mono 10";
    default-timeout = 5000;
    group-by = "summary";
  };

  # ── Swaylock (screen locker) ─────────────────────────────────
  programs.swaylock = {
    settings = {
      color = "${c.base}";
      inside-color = "${c.surface0}ff";
      line-color = "${c.surface1}ff";
      ring-color = "${c.teal}ff";
      separator-color = "00000000";
      inside-ver-color = "${c.blue}ff";
      ring-ver-color = "${c.sapphire}ff";
      inside-wrong-color = "${c.red}ff";
      ring-wrong-color = "${c.maroon}ff";
      key-hl-color = "${c.teal}ff";
      bs-hl-color = "${c.overlay0}ff";
      text-color = "${c.text}ff";
      text-ver-color = "${c.text}ff";
      text-wrong-color = "${c.text}ff";
      font = "JetBrains Mono";
      indicator-radius = 100;
      indicator-thickness = 10;
      show-failed-attempts = true;
    };
  };

  # ── Persistence ──────────────────────────────────────────────
  home.persistence."/persist" = {
    directories = [
      ".config/gtk-3.0"
      ".config/gtk-4.0"
      ".config/fuzzel"
      ".config/mako"
    ];
  };
}
