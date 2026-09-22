{pkgs, ...}: {
  # Generate the signing key once. Keeping it outside the container data prevents
  # image updates from invalidating existing Open WebUI sessions.
  systemd.services.open-webui-secret = {
    description = "Create the Open WebUI signing key";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    before = ["open-webui.service"];
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail
      key_file=/persist/open-webui/open-webui.env

      if [ ! -e "$key_file" ]; then
        umask 0077
        printf 'WEBUI_SECRET_KEY=%s\n' "$( ${pkgs.openssl}/bin/openssl rand -hex 32)" > "$key_file"
      fi
    '';
  };

  environment.etc."containers/systemd/open-webui.container".text = ''
    [Unit]
    Description=Open WebUI
    After=network-online.target caddy-network.service podman-llama.service open-webui-secret.service
    Requires=caddy-network.service podman-llama.service open-webui-secret.service
    RequiresMountsFor=/persist/open-webui

    [Container]
    Image=ghcr.io/open-webui/open-webui:main
    ContainerName=open-webui
    Network=caddy.network
    User=411
    Group=411
    Volume=/persist/open-webui/data:/app/backend/data
    EnvironmentFile=/persist/open-webui/open-webui.env
    Environment=ENABLE_OLLAMA_API=False
    Environment=ENABLE_OPENAI_API=True
    Environment=OPENAI_API_BASE_URLS=http://llama:8080/v1
    Environment=OPENAI_API_KEYS=none
    Environment=ENABLE_PERSISTENT_CONFIG=False
    Environment=OFFLINE_MODE=True
    Environment=WEBUI_AUTH=True
    Environment=TZ=Europe/Paris

    [Service]
    UMask=0077
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
  '';
}
