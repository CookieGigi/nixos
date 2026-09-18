{pkgs, ...}: {
  systemd.tmpfiles.rules = [
    "d /persist/jellyfin/config 0750 jellyfin media -"
    "d /persist/jellyfin/cache  0750 jellyfin media -"
  ];

  system.activationScripts.jellyfin-ownership-migration = ''
    for dir in /persist/jellyfin/config /persist/jellyfin/cache; do
      if [ -d "$dir" ]; then
        ${pkgs.coreutils}/bin/chown -R jellyfin:media "$dir"
      fi
    done
  '';
}
