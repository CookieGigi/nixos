{...}: {
  home.persistence."/persist" = {
    directories = [
      ".config/niri"
      ".ssh"
      "Documents"
      "Downloads"
      "nixos"
    ];
  };
}
