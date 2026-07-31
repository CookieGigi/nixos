{pkgs, ...}: {
  # ===========================================================================
  # Service Users & Shared Media Group
  # ===========================================================================
  # One dedicated user per service. All media-consuming services are added to
  # the `media` group so they can read /media/* as a shared library.
  #
  # UIDs are fixed to keep volume ownership stable across rebuilds.
  #
  #   media       (gid 200)  — shared read access to /media
  #   immich      (uid 300)  — immich server + machine-learning
  #   immich-redis (uid 302)  — valkey cache for immich
  #   immich-db   (uid 999)  — postgres (matches postgres image internal UID)
  #   llama       (uid 303)  — llama.cpp inference server
  #   ai          (gid 202)  — shared read access to /media/ai (model weights)
  # ===========================================================================

  users = {
    groups = {
      media = {
        gid = 200;
        members = ["cookiegigi" "immich"];
      };

      # Shared group so immich server and postgres can both read the DB password secret.
      immich-services = {
        gid = 201;
        members = ["immich" "immich-db"];
      };

      # AI model weights — restricted to llama.cpp only.
      ai = {
        gid = 202;
        members = ["cookiegigi" "llama"];
      };

      # Primary groups for each service user (required by NixOS assertions).
      immich = {};
      immich-redis = {};
      immich-db = {};
      llama = {};
    };

    users = {
      immich = {
        isSystemUser = true;
        uid = 300;
        group = "immich";
        extraGroups = ["media" "immich-services"];
      };

      immich-redis = {
        isSystemUser = true;
        uid = 302;
        group = "immich-redis";
      };

      immich-db = {
        isSystemUser = true;
        uid = 999;
        group = "immich-db";
        extraGroups = ["immich-services"];
      };

      llama = {
        isSystemUser = true;
        uid = 303;
        group = "llama";
        extraGroups = ["ai"];
      };
    };
  };

  # ===========================================================================
  # Directory Layout with Correct Ownership
  # ===========================================================================
  # /media  — warm tier, shared by all media apps via `media` group.
  #           2775 + setgid so new files inherit the `media` group.
  # /backup — cold tier, snapshots.
  # /data   — hot tier, working space.
  # /persist — hot tier, app data owned by the respective service user.
  # ===========================================================================

  systemd.tmpfiles.rules = [
    # -------------------------------------------------------------------------
    # HDD /media — warm tier, shared read access
    # -------------------------------------------------------------------------
    "d /media/pictures             2775 root media -"
    "d /media/videos               2775 root media -"
    "d /media/videos/home          2775 root media -"
    "d /media/videos/movies        2775 root media -"
    "d /media/videos/shows         2775 root media -"
    "d /media/videos/clips         2775 root media -"
    "d /media/videos/music-videos  2775 root media -"
    "d /media/music                2775 root media -"
    "d /media/documents            2775 root media -"
    "d /media/documents/books      2775 root media -"
    "d /media/documents/papers     2775 root media -"
    "d /media/documents/receipts   2775 root media -"
    # AI models — restricted to `ai` group (llama.cpp only).
    "d /media/ai                   0750 root ai -"
    "d /media/ai/llama-models      2770 root ai -"
    "d /media/ai/llama-mmproj      2770 root ai -"

    # -------------------------------------------------------------------------
    # HDD /backup — cold tier
    # -------------------------------------------------------------------------
    "d /backup/media-snapshots   0755 root root -"

    # -------------------------------------------------------------------------
    # HDD /downloads — transient tier
    # -------------------------------------------------------------------------
    "d /downloads                2775 root media -"

    # -------------------------------------------------------------------------
    # NVMe /data — hot tier
    # -------------------------------------------------------------------------
    "d /data/cache               0755 root root -"
    "d /data/hot-media           2775 root media -"
    "d /data/working             0755 root root -"
    "d /data/working/ingest      2775 root media -"

    # -------------------------------------------------------------------------
    # NVMe /persist — app data, owned by service users
    # -------------------------------------------------------------------------
    # Immich
    "d /persist/immich/library     0755 immich immich -"
    "d /persist/immich/model-cache 0755 immich immich -"
    "d /persist/immich/postgres    0700 immich-db immich-db -"

    # Proton Drive sync state
    "d /persist/proton-drive/sync-state 0755 root root -"

    # Backup tooling state
    "d /persist/backups/snapshot-timestamps 0755 root root -"
  ];

  # ===========================================================================
  # Ownership Migration — one-shot activation script
  # ===========================================================================
  # When switching from root-owned directories to service-user ownership,
  # tmpfiles only fixes the top-level directories. Existing files inside
  # /persist/immich/* need a recursive chown so containers can keep working.
  # ===========================================================================

  system.activationScripts.storage-perms-migration = ''
    echo "[storage-layout] Migrating ownership for service users..."

    # Immich app data
    if [ -d /persist/immich/library ]; then
      ${pkgs.coreutils}/bin/chown -R immich:immich /persist/immich/library
      echo "[storage-layout] /persist/immich/library → immich:immich"
    fi

    if [ -d /persist/immich/model-cache ]; then
      ${pkgs.coreutils}/bin/chown -R immich:immich /persist/immich/model-cache
      echo "[storage-layout] /persist/immich/model-cache → immich:immich"
    fi

    if [ -d /persist/immich/postgres ]; then
      ${pkgs.coreutils}/bin/chown -R immich-db:immich-db /persist/immich/postgres
      echo "[storage-layout] /persist/immich/postgres → immich-db:immich-db"
    fi

    # Fix llama.cpp model paths: files were nested inside an extra
    # llama-models/ subdir during a previous migration.
    if [ -d /media/ai/llama-models/llama-models ]; then
      echo "[storage-layout] Fixing nested llama model paths..."
      for f in /media/ai/llama-models/llama-models/*.gguf; do
        [ -e "$f" ] || continue
        basename=$(basename "$f")
        if [ ! -f "/media/ai/llama-models/$basename" ]; then
          ${pkgs.coreutils}/bin/mv "$f" "/media/ai/llama-models/$basename"
          echo "[storage-layout] Moved $basename → /media/ai/llama-models/"
        fi
      done
    fi

    # Llama AI model directories — restrict to `ai` group
    if [ -d /media/ai/llama-models ]; then
      ${pkgs.coreutils}/bin/chown -R root:ai /media/ai/llama-models
      ${pkgs.coreutils}/bin/chmod 2770 /media/ai/llama-models
      echo "[storage-layout] /media/ai/llama-models → root:ai (2770)"
    fi

    if [ -d /media/ai/llama-mmproj ]; then
      ${pkgs.coreutils}/bin/chown -R root:ai /media/ai/llama-mmproj
      ${pkgs.coreutils}/bin/chmod 2770 /media/ai/llama-mmproj
      echo "[storage-layout] /media/ai/llama-mmproj → root:ai (2770)"
    fi

    if [ -d /media/ai ]; then
      ${pkgs.coreutils}/bin/chown root:ai /media/ai
      ${pkgs.coreutils}/bin/chmod 0750 /media/ai
      echo "[storage-layout] /media/ai → root:ai (0750)"
    fi

    # Ensure cookiegigi can write to media via group membership
    # (group changes require a new login, but systemd services are fine)
  '';
}
