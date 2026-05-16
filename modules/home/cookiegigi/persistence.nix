{...}: {
  home.persistence."/persist" = {
    directories = [
      ".ssh"
      "Documents"
      "Downloads"
      "nixos"
    ];
  };
}
