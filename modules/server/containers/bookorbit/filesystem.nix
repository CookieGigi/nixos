{pkgs, ...}: {
  systemd.tmpfiles.rules = [
    "d /persist/bookorbit/app      0750 bookorbit media -"
    "d /persist/bookorbit/postgres 0700 root root -"
    "d /media/documents/books      2775 root media -"
  ];

  system.activationScripts.bookorbit-ownership-migration = ''
    if [ -d /persist/bookorbit/app ]; then
      ${pkgs.coreutils}/bin/chown -R bookorbit:media /persist/bookorbit/app
    fi
  '';
}
