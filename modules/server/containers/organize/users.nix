_: {
  users = {
    groups = {
      organize = {
        gid = 400;
      };

      media.members = ["cookiegigi" "immich" "organize"];
    };

    users.organize = {
      isSystemUser = true;
      uid = 400;
      group = "organize";
      extraGroups = ["media"];
    };
  };
}
