_: {
  systemd.tmpfiles.rules = [
    "d /persist/fileflows/data 0755 root root -"
    "d /persist/fileflows/logs 0755 root root -"
    "d /persist/fileflows/temp 0755 root root -"
  ];
}
