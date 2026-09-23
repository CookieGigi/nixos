{pkgs, ...}: {
  systemd.tmpfiles.rules = [
    # The upstream image runs as its fixed, non-root `ubuntu` user (UID 1000).
    "d /persist/speaches       0750 cookiegigi users -"
    "d /persist/speaches/cache 0700 cookiegigi users -"
  ];

  system.activationScripts.speaches-ownership-migration = ''
    if [ -d /persist/speaches ]; then
      ${pkgs.coreutils}/bin/chown -R cookiegigi:users /persist/speaches
    fi
  '';
}
