{config, ...}: {
  # ===========================================================================
  # sops-nix — Atomic secret provisioning
  # ===========================================================================
  # Secrets are decrypted from the sops file during activation.
  # The age key at /persist/var/lib/sops-nix/key.txt decrypts the file.
  # Secrets land in /run/secrets/ (tmpfs, ephemeral).

  # Default sops file used for all secrets unless overridden per-secret.
  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  # Age key for decryption.
  # The key lives on the LUKS-encrypted persistent volume.
  # If the key doesn't exist yet, sops-nix generates one on first boot.
  sops.age.keyFile = "/persist/var/lib/sops-nix/key.txt";
  sops.age.generateKey = true;

  # ===========================================================================
  # Impermanence — persist the age key across reboots
  # ===========================================================================
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/sops-nix"
    ];
  };

  # ===========================================================================
  # Secrets definitions
  # ===========================================================================

  # User password — decrypted before user creation (neededForUsers = true).
  sops.secrets."user-password" = {
    neededForUsers = true;
  };

  sops.secrets."wifi-home-env" = {
    # The decrypted file will be a valid systemd EnvironmentFile
  };

  # Add more secrets here as needed, e.g.:
  # sops.secrets."github-token" = {};
  # sops.secrets."openai-api-key" = {};
}
