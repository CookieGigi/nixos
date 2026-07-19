_: {
  home.persistence."/persist" = {
    directories = [
      ".ssh"
      "nixos"
      "projects"
      ".opencode"
      ".config/opencode"
      # GNOME Keyring (secret service) persistence for proton-pass-cli
      ".local/share/keyrings"
      # Neovim state
      ".local/share/nvim"
      ".local/state/nvim"
      ".cache/nvim"
    ];
  };
}
