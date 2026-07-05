{
  # SSH
  programs.ssh.startAgent = true;
  services.gnome.gcr-ssh-agent.enable = false;

  programs.ssh = {
    extraConfig = "
      Host server
        Hostname 192.168.1.49
        Port 22
        User cookiegigi
    ";
  };
}
