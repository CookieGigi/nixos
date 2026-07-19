{
  # Firewall
  networking.firewall = {
    enable = true;
    allowPing = true;
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
    };
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
