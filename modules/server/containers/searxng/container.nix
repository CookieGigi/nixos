{pkgs, ...}: let
  settings = (pkgs.formats.yaml {}).generate "searxng-settings.yml" {
    use_default_settings = true;

    general.instance_name = "Cookiegigi Search";

    search.formats = ["html" "json"];

    server = {
      bind_address = "0.0.0.0";
      port = 8080;
      base_url = "https://search.cookiegigi.com/";
      secret_key = "$SEARXNG_SECRET_KEY";
      limiter = false;
      public_instance = false;
    };
  };
in {
  # Persist the key so SearXNG sessions remain valid across image updates.
  systemd.services.searxng-secret = {
    description = "Create the SearXNG signing key";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    before = ["searxng.service"];
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail
      key_file=/persist/searxng/searxng.env

      if [ ! -e "$key_file" ]; then
        umask 0077
        printf 'SEARXNG_SECRET_KEY=%s\n' "$( ${pkgs.openssl}/bin/openssl rand -hex 32)" > "$key_file"
        ${pkgs.coreutils}/bin/chown searxng:searxng "$key_file"
      fi
    '';
  };

  environment.etc."containers/systemd/searxng.container".text = ''
    [Unit]
    Description=SearXNG private meta-search service
    After=network-online.target caddy-network.service searxng-secret.service
    Requires=caddy-network.service searxng-secret.service
    RequiresMountsFor=/persist/searxng

    [Container]
    Image=docker.io/searxng/searxng:latest
    ContainerName=searxng
    Network=caddy.network
    User=412
    Group=412
    Volume=${settings}:/etc/searxng/settings.yml:ro
    Volume=/persist/searxng:/var/cache/searxng
    EnvironmentFile=/persist/searxng/searxng.env
    Environment=TZ=Europe/Paris

    [Service]
    UMask=0077
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
  '';
}
