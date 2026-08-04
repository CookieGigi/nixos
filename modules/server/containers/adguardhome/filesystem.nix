_: {
  systemd.tmpfiles.rules = [
    "d /persist/adguardhome/opt/adguardhome/work 0700 adguardhome adguardhome -"
    "d /persist/adguardhome/opt/adguardhome/conf 0755 adguardhome adguardhome -"
  ];
}
