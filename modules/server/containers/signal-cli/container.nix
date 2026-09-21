{
  environment.etc."containers/systemd/signal-cli.container".text = ''
    [Unit]
    Description=Signal CLI HTTP daemon for Hermes
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
    # Hermes uses the native HTTP API, not the image's REST wrapper.
    Entrypoint=/usr/bin/signal-cli-native
    Exec=--config /home/.local/share/signal-cli daemon --http 0.0.0.0:8080 --no-receive-stdout
    HealthCmd=curl -fsS http://127.0.0.1:8080/api/v1/check
    Environment=TZ=Europe/Paris
    NoNewPrivileges=true

    [Service]
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
  '';
}
