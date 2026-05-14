{
  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"

      "/home/cookiegigi/.ssh"
      "/home/cookiegigi/Documents"
      "/home/cookiegigi/nixos"
      "/home/cookiegigi/Downloads"
      "/home/cookiegigi/.config/mozilla"
    ];
  };
}
