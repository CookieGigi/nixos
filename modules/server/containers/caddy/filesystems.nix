_: {
  systemd.tmpfiles.rules = [
    "d /persist/caddy/etc/caddy 0700 caddy caddy -"
    "d /persist/caddy/srv 0700 caddy caddy -"
    "d /persist/caddy/data 0700 caddy caddy -"
    "d /persist/caddy/config 0700 caddy caddy -"
  ];
}
