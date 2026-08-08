{
  imports = [
    ./core.nix
    ./sops.nix
    ./tpm.nix
    ./localization/frenglish.nix
    ./programs/programs.nix
    ./users/cookiegigi.nix
    ./services/keyring.nix
    ./containers.nix
  ];
}
