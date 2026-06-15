{nixvim, ...}: {
  home-manager.users.cookiegigi = {
    imports = [
      nixvim.homeModules.nixvim
      ./packages.nix
      ./persistence.nix
      ./programs
      ./localization.nix
    ];

    home.stateVersion = "25.11";

    home.shell.enableZshIntegration = true;
  };
}
