{pkgs, ...}: {
  home.packages = with pkgs; [
    wget
    github-copilot-cli
    bubblewrap
    slirp4netns
    github-copilot-app
  ];
}
