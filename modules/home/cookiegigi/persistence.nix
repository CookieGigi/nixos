{...}: {
  home.persistence."/persist" = {
    directories = [
      ".config/niri"
      ".ssh"
      "Documents"
      "Downloads"
      "Pictures"
      "nixos"
    ];
  };
}
