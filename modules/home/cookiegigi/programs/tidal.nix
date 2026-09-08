{pkgs, ...}: {
  home.packages = with pkgs; [
    tidal-hifi
  ];

  xdg.desktopEntries.tidal-hifi = {
    name = "Tidal";
    exec = "tidal-hifi";
    icon = "tidal-hifi";
    categories = ["Audio" "Music"];
  };

  home.persistence."/persist" = {
    directories = [
      ".config/tidal-hifi"
    ];
  };
}
