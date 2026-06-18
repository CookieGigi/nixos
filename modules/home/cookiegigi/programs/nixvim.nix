{pkgs, ...}: {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;

    extraPackages = with pkgs; [
      tree-sitter
    ];

    imports = [
      ./nixvim/base.nix
    ];
  };
}
