{
  pkgs,
  lib,
  ...
}: let
  yazi-flavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "0f9204bc948c8313963f5c9d571a82edc201f8aa";
    sha256 = "14arbad5r33rh71680d20lk62vl94wiczjz8mkz65idf6np40qx9";
  };
in {
  home.packages = with pkgs; [
    file
    yazi
  ];

  # ── Yazi configuration ───────────────────────────────────────
  xdg.configFile = {
    "yazi/yazi.toml".text = ''
      [mgr]
      show_hidden = true

       [opener]
       oculante = [
         { run = "oculante %s", orphan = true, for = "unix"}
       ]
       firefox = [
         { run = "firefox %s", orphan = true, for = "unix" }
       ]

       [open]
       rules=[
         { mime="image/*", use = "oculante" },
         { mime="application/pdf", use = "firefox" },
         { mime="text/html", use = "firefox" },
         { mime="application/xhtml+xml", use = "firefox" },
         { mime="image/svg+xml", use = "firefox" },
         { mime="application/xml", use = "firefox" },
         { mime="text/xml", use = "firefox" },
         { mime="text/*", use = "firefox" },
         { mime="application/json", use = "firefox" },
         { mime="application/javascript", use = "firefox" },
       ]
    '';

    "yazi/theme.toml".text = ''
      [flavor]
      dark = "catppuccin-macchiato"
    '';

    "yazi/flavors/catppuccin-macchiato.yazi" = {
      source = "${yazi-flavors}/catppuccin-macchiato.yazi";
      recursive = true;
    };
  };

  # ── Zsh shell wrapper ──────────────────────────────────────
  programs.zsh.initContent = lib.mkOrder 1000 ''
    # ── Yazi shell wrapper ──────────────────────────────────
    # Change CWD when exiting yazi with `q`, not `Q`
    function y() {
      local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
      command yazi "$@" --cwd-file="$tmp"
      local cwd="$(cat "$tmp")"
      [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
      command rm -f -- "$tmp"
    }
  '';

  # ── Persistence ────────────────────────────────────────────────
  home.persistence."/persist" = {
    directories = [
      ".local/state/yazi"
    ];
  };
}
