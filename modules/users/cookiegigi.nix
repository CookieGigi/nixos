{pkgs, ...}: {
  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.cookiegigi = {
    isNormalUser = true;
    initialPassword = "cookiegigi";
    description = "cookiegigi";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
}
