{pkgs, ...}: {
  home.packages = with pkgs; [
    wifitui
  ];
}
