{
  config,
  pkgs,
  ...
}: {
  # install vim
  programs.vim = {
    enable = true;
    defaultEditor = true;
    package = pkgs.vim-full;
  };
}
