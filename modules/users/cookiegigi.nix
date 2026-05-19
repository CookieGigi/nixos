{pkgs, ...}: {
  users.users.cookiegigi = {
    isNormalUser = true;
    initialPassword = "cookiegigi";
    description = "cookiegigi";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
}
