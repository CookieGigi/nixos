{config, ...}: {
  # ===========================================================================
  # Secrets
  # ===========================================================================
  sops.secrets."immich-db-password" = {
    owner = "root";
    mode = "0400";
  };

  # ===========================================================================
  # Data directories (on /persist, already persistent)
  # ===========================================================================
  systemd.tmpfiles.rules = [
    "d /persist/immich/library     0755 root root -"
    "d /persist/immich/postgres    0755 root root -"
    "d /persist/immich/model-cache 0755 root root -"
  ];

  # ===========================================================================
  # Quadlet units
  # ===========================================================================
  environment.etc = {
    "containers/systemd/immich.network".text = ''
      [Network]
      NetworkName=immich
    '';

    "containers/systemd/immich-redis.container".text = ''
      [Unit]
      Description=Immich Redis (Valkey)
      After=network-online.target

      [Container]
      Image=docker.io/valkey/valkey:9
      ContainerName=immich-redis
      Network=immich.network
      HealthCmd=redis-cli ping || exit 1

      [Service]
      Restart=always

      [Install]
      WantedBy=default.target
    '';

    "containers/systemd/immich-database.container".text = ''
      [Unit]
      Description=Immich Postgres
      After=network-online.target

      [Container]
      Image=ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0
      ContainerName=immich-database
      Network=immich.network
      Volume=/persist/immich/postgres:/var/lib/postgresql/data
      Environment=POSTGRES_USER=postgres
      Environment=POSTGRES_DB=immich
      Environment=POSTGRES_PASSWORD_FILE=${config.sops.secrets."immich-db-password".path}
      Environment=POSTGRES_INITDB_ARGS=--data-checksums
      ShmSize=128mb
      HealthCmd=pg_isready -U postgres -d immich || exit 1

      [Service]
      Restart=always

      [Install]
      WantedBy=default.target
    '';

    "containers/systemd/immich-machine-learning.container".text = ''
      [Unit]
      Description=Immich Machine Learning
      After=network-online.target

      [Container]
      Image=ghcr.io/immich-app/immich-machine-learning:v3
      ContainerName=immich-machine-learning
      Network=immich.network
      Volume=/persist/immich/model-cache:/cache
      Environment=IMMICH_VERSION=v3
      Environment=IMMICH_LOG_LEVEL=log
      Environment=NO_COLOR=false
      Environment=MACHINE_LEARNING_CACHE_FOLDER=/cache

      [Service]
      Restart=always

      [Install]
      WantedBy=default.target
    '';

    "containers/systemd/immich-server.container".text = ''
      [Unit]
      Description=Immich Server
      After=network-online.target immich-redis.service immich-database.service
      Requires=immich-redis.service immich-database.service

      [Container]
      Image=ghcr.io/immich-app/immich-server:v3
      ContainerName=immich-server
      Network=immich.network
      PublishPort=2283:2283
      Volume=/persist/immich/library:/data
      Volume=/etc/localtime:/etc/localtime:ro
      Environment=DB_HOSTNAME=database
      Environment=DB_USERNAME=postgres
      Environment=DB_DATABASE_NAME=immich
      Environment=DB_PASSWORD_FILE=${config.sops.secrets."immich-db-password".path}
      Environment=REDIS_HOSTNAME=redis
      Environment=IMMICH_VERSION=v3
      Environment=IMMICH_MEDIA_LOCATION=/data
      Environment=TZ=Etc/UTC

      [Service]
      Restart=always

      [Install]
      WantedBy=default.target
    '';
  };

  # ===========================================================================
  # Firewall
  # ===========================================================================
  networking.firewall.allowedTCPPorts = [2283];
}
