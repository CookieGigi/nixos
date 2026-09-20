{config, ...}: {
  sops.templates."hermes-dashboard-env" = {
    content = ''
      HERMES_DASHBOARD_BASIC_AUTH_USERNAME=cookiegigi
      HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${config.sops.placeholder."opencode-server-password"}
    '';
    path = "/run/secrets/hermes-dashboard-env";
    mode = "0400";
    restartUnits = ["hermes.service"];
  };
}
