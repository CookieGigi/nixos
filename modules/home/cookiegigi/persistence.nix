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
      # Neovim state
      ".local/share/nvim"
      ".local/state/nvim"
      ".cache/nvim"
    ];
  };
}
