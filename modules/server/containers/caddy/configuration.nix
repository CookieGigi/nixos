{pkgs, ...}: {
  systemd.tmpfiles.rules = [
    "C /etc/caddy/Caddyfile 0644 root root - ${pkgs.writeText "Caddyfile" ''
      photo.cookiegigi.com {
        reverse_proxy :2283
      }
    ''}"
  ];
}
