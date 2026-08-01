_: {
  users = {
    groups = {
      immich-services = {
        gid = 201;
        members = ["immich" "immich-db"];
      };

      immich = {
        gid = 300;
      };
      immich-redis = {
        gid = 305;
      };
      immich-db = {
        gid = 321;
      };
    };

    users = {
      immich = {
        isSystemUser = true;
        uid = 300;
        group = "immich";
        extraGroups = ["media" "immich-services"];
      };

      immich-redis = {
        isSystemUser = true;
        uid = 305;
        group = "immich-redis";
      };

      immich-db = {
        isSystemUser = true;
        uid = 999;
        group = "immich-db";
        extraGroups = ["immich-services"];
      };
    };
  };
}
