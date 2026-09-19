{config, ...}: {
  sops = {
    # Quadlet units are generated at runtime; restart them manually after switching.
    secrets = {
      "bookorbit-db-password" = {};
      "bookorbit-jwt-secret" = {};
      "bookorbit-setup-token" = {};
    };

    templates."bookorbit-db-env" = {
      content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder."bookorbit-db-password"}
      '';
      path = "/run/secrets/bookorbit-db-env";
      mode = "0400";
    };

    templates."bookorbit-app-env" = {
      content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder."bookorbit-db-password"}
        JWT_SECRET=${config.sops.placeholder."bookorbit-jwt-secret"}
        SETUP_BOOTSTRAP_TOKEN=${config.sops.placeholder."bookorbit-setup-token"}
      '';
      path = "/run/secrets/bookorbit-app-env";
      mode = "0400";
    };
  };
}
