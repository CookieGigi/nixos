{
  pkgs,
  pixie-sddm,
  ...
}: {
  programs.niri.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "pixie";
    package = pkgs.kdePackages.sddm;
    extraPackages = [
      pkgs.kdePackages.qtsvg
      pkgs.kdePackages.qtdeclarative
      pkgs.kdePackages.qt5compat
    ];
  };

  environment.systemPackages = [
    (pixie-sddm.packages.${pkgs.stdenv.hostPlatform.system}.pixie-sddm.override {
      background = "/home/cookiegigi/nixos/modules/home/cookiegigi/wallpapers/voyager-4.jpg";
    })
  ];
}
