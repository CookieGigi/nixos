{pkgs, ...}: {
  programs.niri.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
