_: {
  home-manager.users.cookiegigi = {
    imports = [
      ./packages.nix
      ./persistence.nix
      ./programs
      ./localization.nix
    ];

    home.stateVersion = "25.11";

    home.shell.enableZshIntegration = true;
  };
}
