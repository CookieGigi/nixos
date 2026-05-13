{
  disko.devices = {
    disk = {
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
                type = "vfat";
                mountpoint = "/boot";
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cookieluks";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  subvolumes = {
                    # Subvolume name is the same as the mountpoint
                    "/@persist" = {
                      mountOptions = ["compress=zstd:1" "noatime"];
                      mountpoint = "/persist";
                    };
                    "/@nix" = {
                      mountOptions = [
                        "compress=zstd:1"
                        "noatime"
                      ];
                      mountpoint = "/nix";
                    };
                    "/@snapshots" = {
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
