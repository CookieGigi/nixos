_: {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;

    imports = [
      ./nixvim/base.nix
    ];
  };
}
