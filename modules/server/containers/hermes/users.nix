{pkgs, ...}: {
  users.groups.hermes.gid = 409;
  users.users.hermes = {
    isSystemUser = true;
    uid = 409;
    group = "hermes";
  };

  systemd.tmpfiles.rules = [
    "d /persist/hermes 0700 hermes hermes -"
    "d /persist/hermes/plugins 0700 hermes hermes -"
    "d /persist/hermes/plugins/image_gen 0700 hermes hermes -"
  ];

  system.activationScripts.hermes-env-migration = ''
    if [ -L /persist/hermes/.env ]; then
      ${pkgs.coreutils}/bin/rm /persist/hermes/.env
      ${pkgs.coreutils}/bin/install -o hermes -g hermes -m 0600 /dev/null /persist/hermes/.env
    fi
  '';
}
