{...}: {
  programs.niri.enable = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/home/cookiegigi/.config/niri/"
    ];
  };
}
