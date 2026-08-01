{
  config,
  lib,
  ...
}: {
  # Firewall
  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts =
      [8042]
      ++ lib.optionals config.services.reverseProxy.enable [
        80
        443
      ];
  };

  # SSH hardening
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = ["cookiegigi"];
      MaxAuthTries = 3;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      X11Forwarding = false;
      LogLevel = "VERBOSE";
    };
  };

  # Fail2ban
  services.fail2ban = {
    enable = true;
    daemonSettings = {
      DEFAULT = {
        backend = "systemd";
        bantime = "1h";
        "bantime.increment" = true;
        "bantime.rndtime" = "15m";
        "bantime.maxtime" = "1w";
        findtime = "10m";
        maxretry = 3;
      };
    };
    jails = {
      sshd.settings = {
        enabled = true;
        filter = "sshd";
        port = "22";
      };

      caddy = lib.mkIf config.services.reverseProxy.enable {
        settings = {
          enabled = true;
          filter = "caddy";
          backend = "systemd";
          port = "80,443";
          maxretry = 10;
          findtime = "5m";
          bantime = "1h";
        };
      };
    };
  };

  # Custom fail2ban filter for Caddy (JSON access logs in journald).
  # Caddy's default JSON log output includes remote_ip and status fields.
  environment.etc."fail2ban/filter.d/caddy.conf" = lib.mkIf config.services.reverseProxy.enable {
    text = ''
      [Definition]
      failregex = ^.*"remote_ip":"<HOST>".*"status":(?:401|403|429).*
                  ^.*"remote_ip":"<HOST>".*"status":404.*"uri":"/(?:wp-admin|admin|login|wp-login|xmlrpc).*$
      ignoreregex =
      journalmatch = _SYSTEMD_UNIT=caddy.service
    '';
  };

  # Sysctl hardening
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.tcp_syncookies" = 1;
    "kernel.yama.ptrace_scope" = 3;
    "fs.suid_dumpable" = 0;
    "kernel.randomize_va_space" = 3;
  };

  # Persist fail2ban state
  environment.persistence."/persist".directories = [
    "/var/lib/fail2ban"
  ];

  # Preserve HF_TOKEN when using sudo so huggingface-cli works as root.
  security.sudo.extraConfig = ''
    Defaults env_keep += "HF_TOKEN"
  '';
}
