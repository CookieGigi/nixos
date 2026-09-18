{
  users = {
    groups.home-assistant.gid = 403;

    users.home-assistant = {
      isSystemUser = true;
      uid = 403;
      group = "home-assistant";
    };
  };
}
