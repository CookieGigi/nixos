{...}: {
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
  };

  home.persistence."/persist" = {
    directories = [
      ".mozilla"
      ".config/mozilla"
    ];
  };
}
