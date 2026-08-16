_: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;

    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/home/cookiegigi/Games/Steam"
    ];
  };
}
