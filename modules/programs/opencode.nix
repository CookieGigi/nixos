{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.opencode
  ];

  # Persist
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/home/cookiegigi/.config/opencode"
      "/home/cookiegigi/.local/share/opencode"
      "/home/cookiegigi/.local/state/opencode"
    ];
  };
}
