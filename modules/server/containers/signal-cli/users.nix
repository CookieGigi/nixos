{pkgs, ...}: {
  users.groups.signal-cli.gid = 410;
  users.users.signal-cli = {
    isSystemUser = true;
    uid = 410;
    group = "signal-cli";
  };

  systemd.tmpfiles.rules = [
    "d /persist/signal-cli 0700 signal-cli signal-cli -"
  ];

  system.activationScripts.signal-cli-ownership-migration = ''
    if [ -d /persist/signal-cli ]; then
      ${pkgs.coreutils}/bin/chown -R signal-cli:signal-cli /persist/signal-cli
    fi
  '';
}
