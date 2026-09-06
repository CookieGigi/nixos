_: {
  users = {
    groups.bookorbit.gid = 402;

    users.bookorbit = {
      isSystemUser = true;
      uid = 402;
      group = "bookorbit";
      extraGroups = ["media"];
    };
  };
}
