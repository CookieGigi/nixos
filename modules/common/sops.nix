_: {
  # ===========================================================================
  # sops-nix — Atomic secret provisioning
  # ===========================================================================
  # Secrets are decrypted from the sops file during activation.
  # The age key at /persist/var/lib/sops-nix/key.txt decrypts the file.
  # Secrets land in /run/secrets/ (tmpfs, ephemeral).

  sops = {
    # Default sops file used for all secrets unless overridden per-secret.
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    # Age key for decryption.
    # The key lives on the LUKS-encrypted persistent volume.
    # If the key doesn't exist yet, sops-nix generates one on first boot.
    age = {
      keyFile = "/persist/var/lib/sops-nix/key.txt";
      generateKey = true;
    };

    # Secrets definitions
    secrets = {
      "user-password" = {
        neededForUsers = true;
      };
    };
  };

  # ===========================================================================
  # Impermanence — persist the age key across reboots
  # ===========================================================================
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/sops-nix"
    ];
  };

  # Add more secrets here as needed, e.g.:
  # sops.secrets."github-token" = {};
  # sops.secrets."openai-api-key" = {};
}
