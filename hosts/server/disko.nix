{
  disko.devices = {
    disk = {
      # NVMe - Boot, OS, Nix Store
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cookieluks";
                settings = {allowDiscards = true;};
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "/@data" = {
                      mountOptions = ["compress=zstd:1" "noatime"];
                      mountpoint = "/data";
                    };
                    "/@persist" = {
                      mountOptions = ["compress=zstd:1" "noatime"];
                      mountpoint = "/persist";
                    };
                    "/@nix" = {
                      mountOptions = ["compress=zstd:1" "noatime"];
                      mountpoint = "/nix";
                    };
                    "/@snapshots" = {};
                  };
                };
              };
            };
          };
        };
      };

      # SATA HDD - Media Library
      media = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "btrfs";
                subvolumes = {
                  "/@media" = {
                    mountOptions = ["compress=lzo" "noatime"]; # lzo faster for large files
                    mountpoint = "/media";
                  };
                  "/@backup" = {
                    mountOptions = ["compress=lzo" "noatime"]; # lzo faster for large files
                    mountpoint = "/backup";
                  };
                  "/@downloads" = {
                    mountOptions = ["compress=lzo" "noatime"];
                    mountpoint = "/downloads";
                  };
                };
              };
            };
          };
        };
      };
    };

    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = ["size=4G" "mode=755"];
      };
    };
  };
}
