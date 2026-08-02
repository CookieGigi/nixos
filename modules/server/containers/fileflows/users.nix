_: {
  users = {
    groups.fileflows = {
      gid = 401;
    };

    users.fileflows = {
      isSystemUser = true;
      uid = 401;
      group = "fileflows";
      extraGroups = ["media"];
    };
  };
}
