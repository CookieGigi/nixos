{config, ...}: {
  users.users.cookiegigi = {
    isNormalUser = true;
    # Password is stored encrypted in secrets/secrets.yaml (via sops-nix).
    # The hash is decrypted to /run/secrets-for-users/user-password at boot.
    hashedPasswordFile = config.sops.secrets."user-password".path;
    description = "cookiegigi";
    extraGroups = ["networkmanager" "wheel"];
  };
}
