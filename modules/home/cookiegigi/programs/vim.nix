{pkgs, ...}: {
  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-nix # nix syntax + indent
      vim-qml # QML syntax
      vim-hardtime # blocks arrow/repeat hjkl abuse
    ];
    extraConfig = ''
      set number           " absolute line
      set relativenumber   " relative = see distance fast

      " no arrow keys - learn hjkl
      noremap <Up>    <Nop>
      noremap <Down>  <Nop>
      noremap <Left>  <Nop>
      noremap <Right> <Nop>
      inoremap <Up>    <Nop>
      inoremap <Down>  <Nop>
      inoremap <Left>  <Nop>
      inoremap <Right> <Nop>

      " no mouse
      set mouse=

      " hardtime on by default
      let g:hardtime_default_on = 1
    '';
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };
}
