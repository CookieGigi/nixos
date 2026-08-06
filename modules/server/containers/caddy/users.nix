_: {
  users = {
    groups.caddy = {
      gid = 80;
    };

    users.caddy = {
      isSystemUser = true;
      uid = 80;
      group = "caddy";
    };
  };
}
