{pkgs, ...}: {
  systemd.tmpfiles.rules = [
    "d /persist/paperless/data                      0750 paperless media -"
    "d /persist/paperless/media                     0750 paperless media -"
    "d /persist/paperless/media/documents           0750 paperless media -"
    "d /persist/paperless/media/documents/originals 0750 paperless media -"
    "d /persist/paperless/export                    2770 paperless media -"
    "d /persist/paperless/postgres                  0700 paperless-db paperless-db -"
    "d /persist/paperless/broker                    0700 paperless-broker paperless-broker -"
    "d /media/documents/archive                     2750 paperless media -"
    "d /media/documents/inbox                       2770 paperless media -"
  ];

  system.activationScripts.paperless-ownership-migration = ''
    for dir in /persist/paperless/data /persist/paperless/media /persist/paperless/export /media/documents/archive /media/documents/inbox; do
      if [ -d "$dir" ]; then
        ${pkgs.coreutils}/bin/chown -R paperless:media "$dir"
      fi
    done
    if [ -d /persist/paperless/postgres ]; then
      ${pkgs.coreutils}/bin/chown -R paperless-db:paperless-db /persist/paperless/postgres
    fi
    if [ -d /persist/paperless/broker ]; then
      ${pkgs.coreutils}/bin/chown -R paperless-broker:paperless-broker /persist/paperless/broker
    fi
  '';
}
