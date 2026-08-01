_: {
  sops.secrets."immich-db-password" = {
    owner = "root";
    group = "immich-services";
    mode = "0440";
  };
}
