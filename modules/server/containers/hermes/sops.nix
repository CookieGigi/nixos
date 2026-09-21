{config, ...}: {
  sops = {
    secrets."anysearch-api-key" = {};

    templates."hermes-dashboard-env" = {
      content = ''
        HERMES_DASHBOARD_BASIC_AUTH_USERNAME=cookiegigi
        HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${config.sops.placeholder."opencode-server-password"}
        ANYSEARCH_API_KEY=${config.sops.placeholder."anysearch-api-key"}
      '';
      path = "/run/secrets/hermes-dashboard-env";
      mode = "0400";
    };

    templates."hermes-anysearch-env" = {
      content = ''
        ANYSEARCH_API_KEY=${config.sops.placeholder."anysearch-api-key"}
      '';
      path = "/persist/hermes/.env";
      owner = "hermes";
      group = "hermes";
      mode = "0400";
    };
  };
}
