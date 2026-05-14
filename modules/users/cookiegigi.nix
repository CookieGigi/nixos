{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cookiegigi = {
    isNormalUser = true;
    initialPassword = "cookiegigi";
    description = "cookiegigi";
    extraGroups = ["networkmanager" "wheel"];
  };

  # Persist
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/home/cookiegigi/.ssh"
      "/home/cookiegigi/Documents"
      "/home/cookiegigi/nixos"
      "/home/cookiegigi/Downloads"
      "/home/cookiegigi/.config/mozilla"
    ];
  };
}
