_: {
  home.persistence."/persist" = {
    directories = [
      ".ssh"
      # GitHub CLI authentication and configuration
      ".config/gh"
      "Documents"
      "Downloads"
      "Pictures"
      "nixos"
      "Projects"
      ".cache/uad/backups/"
      # GNOME Keyring (secret service) persistence for proton-pass-cli
      ".local/share/keyrings"
      # Neovim state
      ".local/share/nvim"
      ".local/state/nvim"
      ".cache/nvim"
      # Steam
      ".local/share/Steam"
      ".steam"
      "Games/Steam"
      # dev
      ".cache/"
      # uv Python toolchains and state
      ".local/share/uv"
      # GitHub Copilot CLI state
      ".copilot"
      # Stardew Valley (saves, SMAPI logs/config)
      ".config/StardewValley"
    ];
  };
}
