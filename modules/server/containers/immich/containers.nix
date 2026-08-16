{config, ...}: {
  environment.etc = {
    "containers/systemd/immich-internal.network".text = ''
      [Network]
      NetworkName=immich-internal

      [Install]
      WantedBy=multi-user.target
    '';

    "containers/systemd/immich.network".text = ''
      [Network]
      NetworkName=immich

      [Install]
      WantedBy=multi-user.target
    '';

    "containers/systemd/immich-redis.container".text = ''
      [Unit]
      Description=Immich Redis (Valkey)
      After=network-online.target

      [Container]
      Image=docker.io/valkey/valkey:9.1.1
      ContainerName=immich-redis
      User=305
      Group=305
      Network=immich-internal.network
      HealthCmd=redis-cli ping || exit 1

      [Service]
      RestartSec=5
      Restart=always

      [Install]
      WantedBy=multi-user.target
    '';

    "containers/systemd/immich-database.container".text = ''
      [Unit]
      Description=Immich Postgres
      After=network-online.target

      [Container]
      Image=ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0
      ContainerName=immich-database
      User=999
      Group=321
      GroupAdd=201
      Network=immich-internal.network
      Volume=/persist/immich/postgres:/var/lib/postgresql/data
      Volume=${config.sops.secrets."immich-db-password".path}:/run/secrets/immich-db-password:ro
      Environment=POSTGRES_USER=postgres
      Environment=POSTGRES_DB=immich
      Environment=POSTGRES_PASSWORD_FILE=/run/secrets/immich-db-password
      Environment=POSTGRES_INITDB_ARGS=--data-checksums
      ShmSize=128mb
      HealthCmd=pg_isready -U postgres -d immich || exit 1

      [Service]
      RestartSec=5
      Restart=always

      [Install]
      WantedBy=multi-user.target
    '';

    "containers/systemd/immich-machine-learning.container".text = ''
      [Unit]
      Description=Immich Machine Learning
      After=network-online.target

      [Container]
      Image=ghcr.io/immich-app/immich-machine-learning:v3.1.0-cuda
      ContainerName=immich-machine-learning
      User=300
      Group=300
      Network=immich-internal.network
      AddDevice=nvidia.com/gpu=all
      Volume=/persist/immich/model-cache:/cache
      Environment=IMMICH_VERSION=v3
      Environment=IMMICH_LOG_LEVEL=log
      Environment=MACHINE_LEARNING_CACHE_FOLDER=/cache
      Environment=HOME=/cache
      HealthCmd=curl -fsS http://localhost:3003/ping || exit 1
      HealthInterval=30s
      HealthTimeout=10s
      HealthRetries=5
      HealthStartPeriod=120s

      [Service]
      RestartSec=5
      Restart=always

      [Install]
      WantedBy=multi-user.target
    '';

    "containers/systemd/immich-server.container".text = ''
      [Unit]
      Description=Immich Server
      After=network-online.target immich-redis.service immich-database.service immich-machine-learning.service
      Requires=immich-redis.service immich-database.service
      Wants=immich-machine-learning.service

      [Container]
      Image=ghcr.io/immich-app/immich-server:v3.1.0
      ContainerName=immich-server
      User=300
      Group=300
      GroupAdd=201
      Network=immich-internal.network
      Network=immich.network
      AddDevice=nvidia.com/gpu=all
      PublishPort=2283:2283
      Volume=/persist/immich/library:/data
      Volume=/etc/localtime:/etc/localtime:ro
      Volume=/media/pictures:/media/pictures:ro
      Volume=/media/videos:/media/videos:ro
      Environment=DB_HOSTNAME=immich-database
      Environment=DB_USERNAME=postgres
      Environment=DB_DATABASE_NAME=immich
      Environment=DB_PASSWORD_FILE=/run/secrets/immich-db-password
      Volume=${config.sops.secrets."immich-db-password".path}:/run/secrets/immich-db-password:ro
      Environment=REDIS_HOSTNAME=immich-redis
      Environment=IMMICH_VERSION=v3
      Environment=IMMICH_MEDIA_LOCATION=/data
      HealthCmd=/usr/src/app/bin/immich-healthcheck
      HealthInterval=30s
      HealthTimeout=5s
      HealthRetries=5
      HealthStartPeriod=60s

      [Service]
      RestartSec=5
      Restart=always

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
