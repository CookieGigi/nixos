_: {
  users = {
    groups.adguardhome = {
      gid = 53;
    };

    users.adguardhome = {
      isSystemUser = true;
      uid = 53;
      group = "adguardhome";
    };
  };
}
