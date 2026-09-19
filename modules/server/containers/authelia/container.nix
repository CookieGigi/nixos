{
  config,
  lib,
  ...
}: let
  secrets = [
    "authelia-users"
    "authelia-session-secret"
    "authelia-storage-encryption-key"
    "authelia-oidc-hmac-secret"
    "authelia-jwks"
    "authelia-immich-client-digest"
    "authelia-paperless-client-digest"
  ];
in {
  environment.etc = {
    "containers/systemd/authelia.network".text = ''
      [Network]
      NetworkName=authelia
      Internal=true
    '';

    "containers/systemd/authelia.container".text = ''
      [Unit]
      Description=Authelia identity provider
      After=network-online.target sops-install-secrets.service
      RequiresMountsFor=/persist/authelia

      [Container]
      Image=docker.io/authelia/authelia:4.39.22
      ContainerName=authelia
      Network=authelia.network
      User=408
      Group=408
      Volume=${./configuration.yml}:/config/configuration.yml:ro
      Volume=/persist/authelia:/data
      ${lib.concatMapStringsSep "\n" (name: "Volume=${config.sops.secrets.${name}.path}:/secrets/${name}:ro") secrets}
      Environment=X_AUTHELIA_CONFIG_FILTERS=template
      Environment=TZ=Europe/Paris
      DropCapability=all
      NoNewPrivileges=true

      [Service]
      UMask=0077
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
