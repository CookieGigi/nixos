{
  # Register the second LUKS device (medialuks) for systemd-cryptsetup
  # auto-unlock at boot.  This complements modules/common/tpm.nix which
  # already enables systemd initrd and registers cookieluks.
  boot.initrd.luks.devices."medialuks" = {
    device = "/dev/disk/by-partlabel/disk-media-luks";
    allowDiscards = true;
    bypassWorkqueues = false; # SATA HDD — no NVMe optimisations needed
  };
}
