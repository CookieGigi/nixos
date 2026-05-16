{...}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  imports = [
    ./cookiegigi
  ];
}
