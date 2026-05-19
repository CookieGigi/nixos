# sops-nix — Encrypted Secret Management

> How secrets are encrypted, stored, and provisioned in this NixOS flake using [sops-nix](https://github.com/Mic92/sops-nix).

## Overview

Secrets (passwords, API keys, tokens) are stored **encrypted in the git repo** under `secrets/`. At boot, sops-nix decrypts them into `/run/secrets/` (tmpfs) using an **age** key stored on the LUKS-encrypted persistent volume. A **backup key** in Proton Pass ensures disaster recovery.

---

## Key Architecture

| Key | Location | Purpose |
|-----|----------|---------|
| Primary | `/persist/var/lib/sops-nix/key.txt` | Auto-decrypt secrets at boot |
| Backup | Proton Pass (secure note) | Disaster recovery if machine dies |

Both keys are **age** public/private key pairs. The `.sops.yaml` at the repo root lists both as recipients, so either can decrypt.

---

## File Locations

| Path | Purpose | Git Tracked? |
|------|---------|-------------|
| `.sops.yaml` | Encryption rules (which keys can encrypt/decrypt) | ✅ Yes |
| `secrets/secrets.yaml` | Encrypted secrets (passwords, tokens) | ✅ Yes |
| `secrets/secrets.yaml.template` | Reference template (plaintext, for docs only) | ✅ Yes |
| `modules/sops.nix` | NixOS module: sops config + persistence + secret definitions | ✅ Yes |
| `/persist/var/lib/sops-nix/key.txt` | Primary age private key (runtime only) | ❌ No |
| `/run/secrets/` | Decrypted secrets at runtime (tmpfs, wiped on reboot) | ❌ No |

---

## Quick Reference

### Edit secrets

```bash
# Open the encrypted secrets file in your $EDITOR
nix run .#edit-secrets
```

This decrypts `secrets/secrets.yaml`, opens it in your editor, and re-encrypts on save.

### Editing a different file

```bash
nix run .#edit-secrets -- secrets/other.yaml
```

### View decrypted secrets (read-only)

```bash
nix-shell -p sops --run "sops -d secrets/secrets.yaml"
```

### Add a new host key

```bash
# After adding a new recipient to .sops.yaml, update all secrets:
nix-shell -p sops --run "sops updatekeys secrets/secrets.yaml"
```

### Run sops directly

```bash
nix run .#sops -- secrets/secrets.yaml
```

---

## How to Add a New Secret

### 1. Define the secret in `modules/sops.nix`

```nix
# modules/sops.nix
sops.secrets."github-token" = {};

# With custom owner/permissions (optional):
sops.secrets."openai-api-key" = {
  owner = config.users.users.cookiegigi.name;
  group = config.users.users.cookiegigi.group;
  mode = "0400";
};
```

### 2. Add the value to the secrets file

```bash
nix run .#edit-secrets
```

Add your key under `secrets/secrets.yaml`:

```yaml
existing-secret: ENC[...]
github-token: ghp_your_token_here
openai-api-key: sk-your_key_here
```

Save — sops encrypts automatically.

### 3. Use the secret in a NixOS service or user config

The decrypted value is available at `config.sops.secrets."<name>".path`:

```nix
# Example: pass to a systemd service
systemd.services.my-service = {
  serviceConfig.EnvironmentFile = config.sops.secrets."github-token".path;
};

# Example: use as a hashed password (neededForUsers = true required)
users.users.cookiegigi.hashedPasswordFile = config.sops.secrets."user-password".path;
```

### 4. Rebuild

```bash
sudo nixos-rebuild switch --flake .#xps
```

---

## How It Works at Boot

```
Boot → TPM2 unlocks LUKS → /persist mounts
  → sops-nix reads /persist/var/lib/sops-nix/key.txt
  → decrypts secrets/secrets.yaml
  → writes plaintext to /run/secrets/<name>
  → user-password (neededForUsers) goes to /run/secrets-for-users/
  → NixOS creates user with hashed password from decrypted file
  → /run/secrets is tmpfs — gone on next reboot
```

---

## Disaster Recovery

If the machine dies and you need to recover secrets on a new machine:

1. **Retrieve the backup key** from Proton Pass
2. **Place it** at `~/.config/sops/age/keys.txt` on the new machine
3. **Clone this repo** and decrypt:
   ```bash
   nix-shell -p sops --run "sops -d secrets/secrets.yaml"
   ```
4. **Generate a new primary key** and update `.sops.yaml`

---

## Multiple Secrets Formats

sops-nix supports YAML (default), JSON, INI, dotenv, and binary. Override per-secret:

```nix
sops.secrets."env-file" = {
  format = "dotenv";
  sopsFile = ./secrets/production.env;
};
```

---

## Templates

For embedding secrets into config files (e.g., TOML, JSON configs):

```nix
sops.templates."myconfig.toml".content = ''
  api_key = "${config.sops.placeholder.my-secret}"
  database_url = "${config.sops.placeholder.db-url}"
'';

# Reference the rendered file:
# config.sops.templates."myconfig.toml".path
```

---

## Security Notes

- The **primary age key** lives on the LUKS-encrypted persistent volume — protected by full-disk encryption
- At boot, TPM2 automatically unlocks LUKS (no passphrase prompt)
- Secrets are **never in the Nix store** in plaintext — they are decrypted at activation time into `/run/secrets/` (tmpfs)
- The **backup key** in Proton Pass is passphrase-protected (Proton Pass master password)
- **Never** commit raw age private keys or decrypted secrets to git

---

## Reference Links

- sops-nix: https://github.com/Mic92/sops-nix
- sops: https://github.com/getsops/sops
- age encryption: https://github.com/FiloSottile/age
- Current module: `modules/sops.nix`
- Encryption rules: `.sops.yaml`
