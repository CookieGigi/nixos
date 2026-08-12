_: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/home/cookiegigi/Games/Steam"
    ];
  };
}
