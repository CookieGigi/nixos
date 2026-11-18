{
  pkgs,
  config,
  ...
}: let
  background = config.cookiegigi.theme.backgroundColor;
  catppuccinKvantum = pkgs.catppuccin-kvantum.override {
    variant = "macchiato";
    accent = "teal";
  };
  customKvantum = pkgs.runCommand "catppuccin-macchiato-teal-custom" {} ''
    themeDir="$out/share/Kvantum/catppuccin-macchiato-teal-custom"
    mkdir -p "$themeDir"
    cp -a ${catppuccinKvantum}/share/Kvantum/catppuccin-macchiato-teal/. "$themeDir/"
    chmod -R u+w "$themeDir"
    mv "$themeDir/catppuccin-macchiato-teal.kvconfig" "$themeDir/catppuccin-macchiato-teal-custom.kvconfig"
    mv "$themeDir/catppuccin-macchiato-teal.svg" "$themeDir/catppuccin-macchiato-teal-custom.svg"
    substituteInPlace "$themeDir/catppuccin-macchiato-teal-custom.kvconfig" \
      --replace-fail "window.color=#24273A" "window.color=${background}" \
      --replace-fail "base.color=#1E2030" "base.color=${background}"
  '';
  # ── Catppuccin Macchiato Teal palette with configured base ────
  c = {
    base = background;
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
    gtk3 = {
      extraConfig = {
        Settings = ''
          gtk-application-prefer-dark-theme=1
        '';
      };
      extraCss = ''
        window,
        .background {
          background-color: ${background};
        }
      '';
    };
    gtk4 = {
      extraConfig = {
        Settings = ''
          gtk-application-prefer-dark-theme=1
        '';
      };
      extraCss = ''
        window.background {
          background-color: ${background};
        }
      '';
      theme = config.gtk.theme;
    };
  };

  # ── Qt / Kvantum ─────────────────────────────────────────────
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };
  xdg.configFile."Kvantum/kvantum.kvconfig".text = "theme=catppuccin-macchiato-teal-custom\n";

  home.packages = [
    customKvantum
  ];

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
    max-history = 100;
    "mode=do-not-disturb" = {
      invisible = 1;
    };
  };

  # ── Persistence ──────────────────────────────────────────────
  home.persistence."/persist" = {
    directories = [
      ".config/gtk-3.0"
      ".config/gtk-4.0"
      ".config/mako"
    ];
  };
}
