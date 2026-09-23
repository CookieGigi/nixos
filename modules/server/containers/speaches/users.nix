{pkgs, ...}: {
  users.groups.speaches.gid = 412;
  users.users.speaches = {
    isSystemUser = true;
    uid = 412;
    group = "speaches";
  };

  systemd.tmpfiles.rules = [
    "d /persist/speaches       0750 speaches speaches -"
    "d /persist/speaches/cache 0700 speaches speaches -"
  ];

  system.activationScripts.speaches-ownership-migration = ''
    if [ -d /persist/speaches ]; then
      ${pkgs.coreutils}/bin/chown -R speaches:speaches /persist/speaches
    fi
  '';
}
