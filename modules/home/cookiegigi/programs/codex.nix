{pkgs, ...}: {
  home.packages = with pkgs; [
    codex
  ];

  home.persistence."/persist" = {
    directories = [
      ".codex"
    ];
  };
}
