{pkgs, ...}: let
  configuration = pkgs.writeText "home-assistant-configuration.yaml" ''
    default_config:

    http:
      use_x_forwarded_for: true
      trusted_proxies:
        - 10.89.100.2

    automation: !include automations.yaml
    script: !include scripts.yaml
    scene: !include scenes.yaml
  '';
in {
  # A fixed proxy address avoids trusting all containers or the entire LAN.
  environment.etc."containers/systemd/home-assistant-proxy.network".text = ''
    [Network]
    NetworkName=home-assistant-proxy
    Subnet=10.89.100.0/24
    Gateway=10.89.100.1
    Internal=true
  '';

  environment.etc."containers/systemd/home-assistant.container".text = ''
    [Unit]
    Description=Home Assistant
    Wants=network-online.target
    After=network-online.target
    RequiresMountsFor=/persist/home-assistant/config

    [Container]
    Image=ghcr.io/home-assistant/home-assistant:stable
    ContainerName=home-assistant
    Network=host
    User=403
    Group=403
    Volume=/persist/home-assistant/config:/config
    Volume=${configuration}:/config/configuration.yaml:ro
    Environment=TZ=Europe/Paris
    Environment=HOME=/config
    WorkingDir=/config
    # Run Home Assistant directly rather than the image's root-only s6 init.
    Entrypoint=python3
    Exec=-P -m homeassistant --config /config
    DropCapability=all
    NoNewPrivileges=true

    [Service]
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
  '';
}
