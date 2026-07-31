_: {
  # ===========================================================================
  # Shared Media Group
  # ===========================================================================
  # All media-consuming services are added to the `media` group so they can
  # read /media/* as a shared library.
  # ===========================================================================

  users = {
    groups = {
      media = {
        gid = 200;
        members = ["cookiegigi" "immich"];
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
    # Proton Drive sync state
    "d /persist/proton-drive/sync-state 0755 root root -"

    # Backup tooling state
    "d /persist/backups/snapshot-timestamps 0755 root root -"
  ];
}
