{pkgs, ...}: {
  home.packages = with pkgs; [
    wget
    github-copilot-cli
    github-copilot-app
  ];
}
