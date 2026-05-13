{lib, ...}: {
  boot.loader.systemd-boot.enable = lib.mkForce false;
  isoImage.squashfsCompression = "zstd";
  boot.supportedFilesystems = lib.mkForce ["btrfs" "vfat" "ext4"];
}
