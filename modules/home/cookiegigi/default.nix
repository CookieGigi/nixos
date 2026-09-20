{
  config,
  inputs,
  ...
}: {
  sops.secrets."hf-token" = {
    owner = config.users.users.cookiegigi.name;
    mode = "0400";
  };

  home-manager.extraSpecialArgs = {inherit inputs;};

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
