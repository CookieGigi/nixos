_: {
  home.persistence."/persist" = {
    directories = [
      ".ssh"
      "nixos"
      "projects"
      ".opencode"
      ".config/opencode"
      # GitHub Copilot CLI state
      ".copilot"
      # GNOME Keyring (secret service) persistence for proton-pass-cli
      ".local/share/keyrings"
      # pass + GPG for proton-drive CLI
      ".gnupg"
      ".password-store"
      # Neovim state
      ".local/share/nvim"
      ".local/state/nvim"
      ".cache/nvim"
    ];
  };
}
