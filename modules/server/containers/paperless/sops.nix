{config, ...}: {
  sops = {
    secrets = {
      "paperless-db-password".sopsFile = ../../../../secrets/paperless.yaml;
      "paperless-secret-key".sopsFile = ../../../../secrets/paperless.yaml;
    };

    templates."paperless-db-env" = {
      content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder."paperless-db-password"}
      '';
      path = "/run/secrets/paperless-db-env";
      mode = "0400";
      restartUnits = ["paperless-db.service"];
    };

    templates."paperless-app-env" = {
      content = ''
        PAPERLESS_DBPASS=${config.sops.placeholder."paperless-db-password"}
        PAPERLESS_SECRET_KEY=${config.sops.placeholder."paperless-secret-key"}
      '';
      path = "/run/secrets/paperless-app-env";
      mode = "0400";
      restartUnits = ["paperless.service"];
    };
  };
}
