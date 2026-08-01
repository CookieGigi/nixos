{
  config,
  pkgs,
  ...
}: {
  # OpenCode headless server — now bound to localhost only.
  # Access is via the reverse proxy (opencode.cookiegigi.com).
  systemd.services.opencode-serve = {
    description = "OpenCode headless server";
    wantedBy = ["multi-user.target"];
    after = [
      "network.target"
      "podman-llama.service"
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
        exec ${pkgs.opencode}/bin/opencode serve --hostname 127.0.0.1 --port 4096
      '';
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
