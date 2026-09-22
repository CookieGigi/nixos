{pkgs, ...}: {
  users.groups.open-webui.gid = 411;
  users.users.open-webui = {
    isSystemUser = true;
    uid = 411;
    group = "open-webui";
  };

  systemd.tmpfiles.rules = [
    "d /persist/open-webui      0750 root       root       -"
    "d /persist/open-webui/data 0700 open-webui open-webui -"
  ];

  system.activationScripts.open-webui-ownership-migration = ''
    if [ -d /persist/open-webui/data ]; then
      ${pkgs.coreutils}/bin/chown -R open-webui:open-webui /persist/open-webui/data
    fi
  '';
}
