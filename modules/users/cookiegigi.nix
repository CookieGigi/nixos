{pkgs, ...}: {
  users.users.cookiegigi = {
    isNormalUser = true;
    # Password is set manually with `passwd` — survives reboots because
    # /etc/shadow is persisted via impermanence (see modules/core.nix)
    description = "cookiegigi";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
}
