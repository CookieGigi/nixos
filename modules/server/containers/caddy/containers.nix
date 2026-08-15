_: {
  environment.etc."containers/systemd/caddy.container".text = ''
    [Unit]
    Description=Caddy
    After=network-online.target

    [Container]
    Image=zot.cookiegigi.com:5050/caddy-cloudflare:2.11.4
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
    EnvironmentFile=/run/secrets/caddy-env

    [Service]
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
  '';
}
