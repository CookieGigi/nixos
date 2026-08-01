{pkgs, ...}: {
  systemd.tmpfiles.rules = [
    "d /persist/immich/library     0755 immich immich -"
    "d /persist/immich/model-cache 0755 immich immich -"
    "d /persist/immich/postgres    0700 immich-db immich-db -"
  ];

  system.activationScripts.immich-ownership-migration = ''
    echo "[immich] Migrating ownership for immich service directories..."

    if [ -d /persist/immich/library ]; then
      ${pkgs.coreutils}/bin/chown -R immich:immich /persist/immich/library
      echo "[immich] /persist/immich/library -> immich:immich"
    fi

    if [ -d /persist/immich/model-cache ]; then
      ${pkgs.coreutils}/bin/chown -R immich:immich /persist/immich/model-cache
      echo "[immich] /persist/immich/model-cache -> immich:immich"
    fi

    if [ -d /persist/immich/postgres ]; then
      ${pkgs.coreutils}/bin/chown -R immich-db:immich-db /persist/immich/postgres
      echo "[immich] /persist/immich/postgres -> immich-db:immich-db"
    fi
  '';
}
