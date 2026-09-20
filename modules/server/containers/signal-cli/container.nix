{
  environment.etc."containers/systemd/signal-cli.container".text = ''
    [Unit]
    Description=Signal CLI REST API
    After=network-online.target caddy-network.service
    Requires=caddy-network.service
    RequiresMountsFor=/persist/signal-cli

    [Container]
    Image=docker.io/bbernhard/signal-cli-rest-api:rootless-latest
    ContainerName=signal-cli
    Network=caddy.network
    User=410
    Group=410
    Volume=/persist/signal-cli:/home/.local/share/signal-cli
    Environment=MODE=json-rpc-native
    Environment=TZ=Europe/Paris
    NoNewPrivileges=true

    [Service]
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
  '';
}
