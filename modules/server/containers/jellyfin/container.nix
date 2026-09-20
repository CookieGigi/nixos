{
  environment.etc = {
    "containers/systemd/jellyfin.network".text = ''
      [Network]
      NetworkName=jellyfin
    '';

    "containers/systemd/jellyfin.container".text = ''
      [Unit]
      Description=Jellyfin media server
      Wants=network-online.target
      After=network-online.target
      RequiresMountsFor=/persist/jellyfin /media/videos /media/music

      [Container]
      Image=docker.io/jellyfin/jellyfin:latest
      ContainerName=jellyfin
      Network=jellyfin.network
      User=407
      Group=200
      Volume=/persist/jellyfin/config:/config
      Volume=/persist/jellyfin/cache:/cache
      Volume=/media/videos:/media/videos:ro
      Volume=/media/music:/media/music:ro
      Environment=TZ=Europe/Paris
      DropCapability=all
      NoNewPrivileges=true

      [Service]
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
