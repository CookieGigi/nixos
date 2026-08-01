{
  # Register the second LUKS device (medialuks) for systemd-cryptsetup
  # auto-unlock at boot.  This complements modules/common/tpm.nix which
  # already enables systemd initrd and registers cookieluks.
  boot.initrd.luks.devices = {
    "cookieluks" = {
      device = "/dev/disk/by-partlabel/disk-main-luks";
      allowDiscards = true;
      bypassWorkqueues = true; # NVMe I/O performance optimisation
    };
  };
}
