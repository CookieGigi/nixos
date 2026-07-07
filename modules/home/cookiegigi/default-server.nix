{nixvim, ...}: {
  home-manager.users.cookiegigi = {
    imports = [
      nixvim.homeModules.nixvim
      ./packages.nix
      ./persistence-server.nix
      ./programs/default-server.nix
      ./localization.nix
    ];

    home.stateVersion = "25.11";

    home.shell.enableZshIntegration = true;
  };
}
