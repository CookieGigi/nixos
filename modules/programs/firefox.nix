{
  # Install firefox.
  programs.firefox.enable = true;

  # Persist
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/home/cookiegigi/.config/mozilla"
    ];
  };
}
