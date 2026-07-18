{
  # Public keys are not secrets — safe to keep in plain text in the repo.
  # The matching private key stays on the xps (~/.ssh/id_ed25519).
  users.users.cookiegigi.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDANNAAqC6VheKXQRqV1Nw8XUznTgzPpdmE43/ZRC27g cookiegigi@cookiegigi.com"
  ];
}
