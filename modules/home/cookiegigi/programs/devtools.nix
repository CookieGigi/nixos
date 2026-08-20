{pkgs, ...}: {
  home.packages = with pkgs; [
    alejandra
    statix
    deadnix
    s-tui
  ];
}
