{pkgs, ...}: {
  home.packages = with pkgs; [
    prismlauncher
  ];

  home.persistence."/persist" = {
    directories = [
      # Instances, worlds and mods
      "PrismLauncher"
      ".config/PrismLauncher"
      ".local/share/PrismLauncher"
    ];
  };
}
