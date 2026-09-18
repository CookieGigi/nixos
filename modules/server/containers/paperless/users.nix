{
  users = {
    groups = {
      paperless.gid = 404;
      paperless-db.gid = 405;
      paperless-broker.gid = 406;
    };

    users = {
      paperless = {
        isSystemUser = true;
        uid = 404;
        group = "paperless";
        extraGroups = ["media"];
      };
      paperless-db = {
        isSystemUser = true;
        uid = 405;
        group = "paperless-db";
      };
      paperless-broker = {
        isSystemUser = true;
        uid = 406;
        group = "paperless-broker";
      };
    };
  };
}
