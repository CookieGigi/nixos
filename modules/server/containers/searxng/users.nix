{pkgs, ...}: {
  users.groups.searxng.gid = 412;
  users.users.searxng = {
    isSystemUser = true;
    uid = 412;
    group = "searxng";
  };

  systemd.tmpfiles.rules = [
    "d /persist/searxng 0700 searxng searxng -"
  ];

  system.activationScripts.searxng-ownership-migration = ''
    if [ -d /persist/searxng ]; then
      ${pkgs.coreutils}/bin/chown -R searxng:searxng /persist/searxng
    fi
  '';
}
