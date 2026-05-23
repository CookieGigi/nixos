{...}: {
  home.persistence."/persist" = {
    directories = [
      ".config/niri"
      ".config/quickshell"
      ".ssh"
      "Documents"
      "Downloads"
      "Pictures"
      "nixos"
      "Projects"
    ];
  };
}
