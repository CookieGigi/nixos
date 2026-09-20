{pkgs, ...}: let
  initialConfig = (pkgs.formats.yaml {}).generate "hermes-config.yaml" {
    model = {
      provider = "custom";
      default = "Ornith-1.5-9B-Q5_K_M";
      base_url = "http://llama:8080/v1";
      api_key = "none";
      api_mode = "chat_completions";
    };

    terminal.backend = "local";

    dashboard.public_url = "https://hermes.cookiegigi.com";
  };

  seedConfig = pkgs.writeShellScript "hermes-seed-config" ''
    set -euo pipefail

    if [ ! -e /persist/hermes/config.yaml ]; then
      ${pkgs.coreutils}/bin/install -o 409 -g 409 -m 0600 \
        ${initialConfig} /persist/hermes/config.yaml
    else
      ${pkgs.gnused}/bin/sed -i -E \
        's|^([[:space:]]*default:[[:space:]]*)Qwen3\.5-4B-Q6_K([[:space:]]*)$|\1Ornith-1.5-9B-Q5_K_M\2|' \
        /persist/hermes/config.yaml
    fi
  '';
in {
  environment.etc."containers/systemd/hermes.container".text = ''
    [Unit]
    Description=Hermes Agent
    After=network-online.target caddy-network.service podman-llama.service
    Requires=caddy-network.service podman-llama.service
    RequiresMountsFor=/persist/hermes

    [Container]
    Image=docker.io/nousresearch/hermes-agent:latest
    ContainerName=hermes
    Network=caddy.network
    Volume=/persist/hermes:/opt/data
    Environment=HERMES_UID=409
    Environment=HERMES_GID=409
    Environment=HERMES_DASHBOARD=1
    Environment=HERMES_GATEWAY_BOOTSTRAP_STATE=running
    Environment=TZ=Europe/Paris
    EnvironmentFile=/run/secrets/hermes-dashboard-env
    Exec=gateway run

    [Service]
    ExecStartPre=${seedConfig}
    UMask=0077
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
  '';
}
