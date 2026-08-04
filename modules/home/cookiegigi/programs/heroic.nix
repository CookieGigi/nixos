{pkgs, ...}: {
  home.packages = with pkgs; [
    heroic
  ];

  home.persistence."/persist" = {
    directories = [
      "Games/Heroic"
      ".config/heroic"
      ".config/unity3d"
    ];
  };
}
