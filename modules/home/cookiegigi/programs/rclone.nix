{pkgs, ...}: {
  home.packages = with pkgs; [
    rclone
  ];

  home.persistence."/persist/home/gigi" = {
    files = [".config/rclone/rclone.conf"];
  };
}
