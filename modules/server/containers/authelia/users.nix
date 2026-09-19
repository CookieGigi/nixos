{
  users.groups.authelia.gid = 408;
  users.users.authelia = {
    isSystemUser = true;
    uid = 408;
    group = "authelia";
  };

  systemd.tmpfiles.rules = [
    "d /persist/authelia 0700 authelia authelia -"
  ];
}
