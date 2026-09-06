{pkgs, ...}: {
  environment.etc = {
    "containers/systemd/bookorbit.network".text = ''
      [Network]
      NetworkName=bookorbit

      [Install]
      WantedBy=multi-user.target
    '';

    "containers/systemd/bookorbit-db.container".text = ''
      [Unit]
      Description=BookOrbit PostgreSQL
      After=network-online.target

      [Container]
      Image=docker.io/pgvector/pgvector:pg18
      ContainerName=bookorbit-db
      Network=bookorbit.network
      Volume=/persist/bookorbit/postgres:/var/lib/postgresql/data
      EnvironmentFile=/run/secrets/bookorbit-db-env
      Environment=POSTGRES_USER=bookorbit
      Environment=POSTGRES_DB=bookorbit
      Environment=PGDATA=/var/lib/postgresql/data/pgdata
      HealthCmd=pg_isready -U bookorbit -d bookorbit || exit 1
      HealthInterval=10s
      HealthTimeout=5s
      HealthRetries=10
      HealthStartPeriod=20s

      [Service]
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
    '';

    "containers/systemd/bookorbit.container".text = ''
      [Unit]
      Description=BookOrbit
      After=network-online.target bookorbit-db.service
      Requires=bookorbit-db.service

      [Container]
      Image=ghcr.io/bookorbit/bookorbit:latest
      ContainerName=bookorbit
      Network=bookorbit.network
      PublishPort=192.168.1.49:3000:3000
      Volume=/persist/bookorbit/app:/data
      Volume=/media/documents/books:/books
      EnvironmentFile=/run/secrets/bookorbit-app-env
      Environment=NODE_ENV=production
      Environment=PORT=3000
      Environment=POSTGRES_HOST=bookorbit-db
      Environment=POSTGRES_PORT=5432
      Environment=POSTGRES_USER=bookorbit
      Environment=POSTGRES_DB=bookorbit
      Environment=APP_URL=https://bookorbit.cookiegigi.com
      Environment=CLIENT_URL=https://bookorbit.cookiegigi.com
      Environment=TZ=Europe/Paris
      Environment=PUID=402
      Environment=PGID=200
      Environment=NODE_MAX_OLD_SPACE_SIZE=auto
      Environment=LIBRARY_BROWSE_ROOT=/books
      RunInit=true
      ReadOnly=true
      Tmpfs=/tmp:rw,mode=1777
      DropCapability=all
      AddCapability=chown dac_override fowner setgid setuid
      NoNewPrivileges=true
      StopTimeout=30

      [Service]
      ExecStartPre=${pkgs.podman}/bin/podman wait --condition=healthy bookorbit-db
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
