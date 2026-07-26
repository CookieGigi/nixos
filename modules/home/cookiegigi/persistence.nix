_: {
  home.persistence."/persist" = {
    directories = [
      ".ssh"
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
    ];
  };
}
