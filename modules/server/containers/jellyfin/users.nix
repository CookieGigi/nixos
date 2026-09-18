{
  users = {
    groups.jellyfin.gid = 407;

    users.jellyfin = {
      isSystemUser = true;
      uid = 407;
      group = "jellyfin";
      extraGroups = ["media"];
    };
  };
}
