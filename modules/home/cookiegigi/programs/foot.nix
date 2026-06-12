{pkgs, ...}: {
  programs.foot = {
    enable = true;

    settings = {
      main = {
        font = "JetBrains Mono:size=12";
        alpha = 0.8;
      };

      include = "${pkgs.foot}/share/foot/themes/catppuccin-macchiato";
    };
  };

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
