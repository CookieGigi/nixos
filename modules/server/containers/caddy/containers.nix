_: {
  environment.etc."containers/systemd/caddy.container".text = ''
    [Unit]
    Description=Caddy
    After=network-online.target

    [Container]
    Image=docker.io/library/caddy:latest
    ContainerName=caddy
    PublishPort=80:80
    PublishPort=443:443
    PublishPort=443:443/udp
    Volume=/etc/caddy:/etc/caddy
    Volume=/persist/caddy/srv:/srv
    Volume=/persist/caddy/data:/data
    Volume=/persist/caddy/config:/config
    UserNS=keep-id:uid=80,gid=80
    Environment=TZ=Europe/Paris

    [Service]
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
  '';
}
