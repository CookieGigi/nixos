{
  nixvim,
  inputs,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupCommand = ''
      mv -f "$1" "$1.$(date +%s).hm-backup"
    '';
    extraSpecialArgs = {inherit nixvim inputs;};
  };

  imports = [
    ./cookiegigi
  ];
}
