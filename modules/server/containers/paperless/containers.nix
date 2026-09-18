{pkgs, ...}: {
  environment.etc = {
    "containers/systemd/paperless.network".text = ''
      [Network]
      NetworkName=paperless
    '';

    "containers/systemd/paperless-db.container".text = ''
      [Unit]
      Description=Paperless PostgreSQL
      After=network-online.target
      RequiresMountsFor=/persist/paperless/postgres

      [Container]
      Image=docker.io/library/postgres:18
      ContainerName=paperless-db
      Network=paperless.network
      User=405
      Group=405
      Volume=/persist/paperless/postgres:/var/lib/postgresql
      Mount=type=tmpfs,destination=/var/run/postgresql,tmpfs-mode=0770,U=true
      EnvironmentFile=/run/secrets/paperless-db-env
      Environment=POSTGRES_USER=paperless
      Environment=POSTGRES_DB=paperless
      Environment=PGDATA=/var/lib/postgresql/18/docker
      HealthCmd=pg_isready -U paperless -d paperless
      HealthInterval=10s
      HealthTimeout=5s
      HealthRetries=10
      HealthStartPeriod=20s
      DropCapability=all
      NoNewPrivileges=true

      [Service]
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
    '';

    "containers/systemd/paperless-broker.container".text = ''
      [Unit]
      Description=Paperless Valkey broker
      After=network-online.target
      RequiresMountsFor=/persist/paperless/broker

      [Container]
      Image=docker.io/valkey/valkey:9-alpine
      ContainerName=paperless-broker
      Network=paperless.network
      User=406
      Group=406
      Volume=/persist/paperless/broker:/data
      Exec=valkey-server --appendonly yes
      HealthCmd=valkey-cli ping
      HealthInterval=10s
      HealthTimeout=5s
      HealthRetries=10
      DropCapability=all
      NoNewPrivileges=true

      [Service]
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
    '';

    "containers/systemd/paperless.container".text = ''
      [Unit]
      Description=Paperless-ngx
      After=network-online.target paperless-db.service paperless-broker.service
      Requires=paperless-db.service paperless-broker.service
      RequiresMountsFor=/persist/paperless /media/documents/archive /media/documents/inbox

      [Container]
      Image=ghcr.io/paperless-ngx/paperless-ngx:latest
      ContainerName=paperless
      Network=paperless.network
      PublishPort=192.168.1.49:8000:8000
      User=404
      Group=200
      Volume=/persist/paperless/data:/usr/src/paperless/data
      Volume=/persist/paperless/media:/usr/src/paperless/media
      Volume=/media/documents/archive:/usr/src/paperless/media/documents/originals
      Volume=/persist/paperless/export:/usr/src/paperless/export
      Volume=/media/documents/inbox:/usr/src/paperless/consume
      EnvironmentFile=/run/secrets/paperless-app-env
      Environment=PAPERLESS_REDIS=redis://paperless-broker:6379
      Environment=PAPERLESS_DBENGINE=postgresql
      Environment=PAPERLESS_DBHOST=paperless-db
      Environment=PAPERLESS_DBNAME=paperless
      Environment=PAPERLESS_DBUSER=paperless
      Environment=PAPERLESS_URL=https://paperless.cookiegigi.com
      Environment=PAPERLESS_TIME_ZONE=Europe/Paris
      Environment=PAPERLESS_OCR_LANGUAGE=fra+eng
      Environment=TZ=Europe/Paris
      DropCapability=all
      NoNewPrivileges=true

      [Service]
      ExecStartPre=${pkgs.podman}/bin/podman wait --condition=healthy paperless-db
      ExecStartPre=${pkgs.podman}/bin/podman wait --condition=healthy paperless-broker
      Restart=always
      RestartSec=5
      TimeoutStartSec=300

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
