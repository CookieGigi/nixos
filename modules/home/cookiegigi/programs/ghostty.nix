{pkgs, ...}: {
  programs.ghostty = {
    enable = true;

    # ── Shell integration ────────────────────────────────────────
    enableZshIntegration = true;

    # ── Appearance ───────────────────────────────────────────────
    settings = {
      theme = "Catppuccin Macchiato";
      font-family = "JetBrains Mono";
      font-size = 12;
      background-opacity = 0.8;
    };

    # ── Behaviour ────────────────────────────────────────────────
    clearDefaultKeybinds = false;
  };

  # ── Font dependency ────────────────────────────────────────────
  home.packages = [
    pkgs.jetbrains-mono
  ];

  # ── Persistence ────────────────────────────────────────────────
  home.persistence."/persist" = {
    directories = [
      ".config/ghostty"
    ];
  };
}
