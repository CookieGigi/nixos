{lib, ...}: {
  boot.loader.systemd-boot.enable = lib.mkForce false;
  isoImage.squashfsCompression = "zstd";
}
