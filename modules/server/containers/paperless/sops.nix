{config, ...}: {
  sops = {
    # Quadlet units are generated at runtime; restart them manually after switching.
    secrets = {
      "paperless-db-password".sopsFile = ../../../../secrets/paperless.yaml;
      "paperless-secret-key".sopsFile = ../../../../secrets/paperless.yaml;
      "authelia-paperless-client-secret" = {};
    };

    templates."paperless-db-env" = {
      content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder."paperless-db-password"}
      '';
      path = "/run/secrets/paperless-db-env";
      mode = "0400";
    };

    templates."paperless-app-env" = {
      content = ''
        PAPERLESS_DBPASS=${config.sops.placeholder."paperless-db-password"}
        PAPERLESS_SECRET_KEY=${config.sops.placeholder."paperless-secret-key"}
        PAPERLESS_SOCIALACCOUNT_PROVIDERS=${builtins.toJSON {
          openid_connect = {
            SCOPE = ["openid" "profile" "email"];
            OAUTH_PKCE_ENABLED = true;
            EMAIL_AUTHENTICATION = false;
            APPS = [
              {
                provider_id = "authelia";
                name = "Authelia";
                client_id = "paperless";
                secret = config.sops.placeholder."authelia-paperless-client-secret";
                settings = {
                  server_url = "https://auth.cookiegigi.com";
                  token_auth_method = "client_secret_basic";
                };
              }
            ];
          };
        }}
      '';
      path = "/run/secrets/paperless-app-env";
      mode = "0400";
    };
  };
}
