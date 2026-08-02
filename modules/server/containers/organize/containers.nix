_: {
  environment.etc = {
    "containers/systemd/organize.container".text = ''
      [Unit]
      Description=Organize - file sorter
      After=local-fs.target

      [Container]
      Image=ghcr.io/tfeldmann/organize:latest
      ContainerName=organize
      User=400
      Group=400
      Exec=run
      Volume=/persist/organize/config.yml:/config/config.yml:ro
      Volume=/downloads:/downloads
      Volume=/media/pictures:/media/pictures
      Volume=/media/videos:/media/videos
      Volume=/media/music:/media/music
      Volume=/media/documents:/media/documents

      [Service]
      Type=oneshot
    '';

    "containers/systemd/organize.timer".text = ''
      [Unit]
      Description=Organize - file sorter timer

      [Timer]
      OnBootSec=2min
      OnUnitActiveSec=5min
      Unit=organize.service

      [Install]
      WantedBy=timers.target
    '';
  };
}
