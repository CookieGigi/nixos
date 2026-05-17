{pkgs, ...}: {
  programs.ghostty = {
    enable = true;

    # ── Shell integration ────────────────────────────────────────
    enableZshIntegration = true;

    # ── Appearance ───────────────────────────────────────────────
    settings = {
      theme = "catppuccin-macchiato";
      font-family = "JetBrains Mono";
      font-size = 12;
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
