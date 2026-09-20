{
  users.groups.hermes.gid = 409;
  users.users.hermes = {
    isSystemUser = true;
    uid = 409;
    group = "hermes";
  };

  systemd.tmpfiles.rules = [
    "d /persist/hermes 0700 hermes hermes -"
  ];
}
