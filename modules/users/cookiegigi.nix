{pkgs, ...}: {
  users.users.cookiegigi = {
    isNormalUser = true;
    # Password is set manually with `passwd` after install — not in public config
    description = "cookiegigi";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
}
