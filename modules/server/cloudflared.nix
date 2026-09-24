{
  config,
  pkgs,
  ...
}: {
  sops.secrets."cloudflared-tunnel-token" = {};

  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target" "sops-install-secrets.service"];
    requires = ["sops-install-secrets.service"];
    serviceConfig = {
      DynamicUser = true;
      LoadCredential = "tunnel-token:${config.sops.secrets."cloudflared-tunnel-token".path}";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file %d/tunnel-token";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      PrivateTmp = true;
    };
  };
}
