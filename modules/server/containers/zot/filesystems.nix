_: {
  systemd.tmpfiles.rules = [
    "d /persist/zot/registry 0700 zot zot -"
  ];
}
