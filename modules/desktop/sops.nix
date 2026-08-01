_: {
  sops = {
    secrets = {
      "wifi-home-env" = {
        # The decrypted file will be a valid systemd EnvironmentFile
      };
    };
  };
}
