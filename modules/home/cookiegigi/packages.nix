{pkgs, ...}: {
  home.packages = with pkgs; [
    wget
    github-copilot-cli
    bubblewrap
    github-copilot-app
  ];
}
