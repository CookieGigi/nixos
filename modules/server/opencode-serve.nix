{
  config,
  pkgs,
  ...
}: {
  # Open firewall for the OpenCode server API.
  networking.firewall.allowedTCPPorts = [4096];

  # OpenCode headless server — always-on, accessible from LAN and Android app.
  systemd.services.opencode-serve = {
    description = "OpenCode headless server";
    wantedBy = ["multi-user.target"];
    after = [
      "network.target"
      "llama-cpp.service"
    ];

    serviceConfig = {
      Type = "simple";
      User = "cookiegigi";
      Group = "users";
      WorkingDirectory = "/home/cookiegigi/projects";
      Environment = [
        "LOCAL_ENDPOINT=http://localhost:8080/v1"
        "OPENCODE_SERVER_USERNAME=opencode"
      ];
      ExecStart = pkgs.writeShellScript "opencode-serve" ''
        export OPENCODE_SERVER_PASSWORD=$(cat ${config.sops.secrets."opencode-server-password".path})
        exec ${pkgs.opencode}/bin/opencode serve --hostname 0.0.0.0 --port 4096
      '';
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
