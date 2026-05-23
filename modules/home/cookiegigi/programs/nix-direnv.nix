{
  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };
  };

  home.persistence."/persist" = {
    directories = [
      ".local/share/direnv"
      ".cache/direnv"
    ];
  };
}
