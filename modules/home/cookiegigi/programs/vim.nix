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
            set mouse= " hardtime on by default
            let g:hardtime_default_on = 1
            let g:hardtime_default_on = 1        " on for all buffers
      let g:hardtime_timeout = 2000        " block window ms (default 2000)
      let g:hardtime_maxcount = 2          " allow N repeats before block
      let g:hardtime_allow_different_key = 1  " jkjkjk ok, jjj bad
      let g:hardtime_showmsg = 1           " show message when blocked
    '';
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };
}
