# NixOS Install Walkthrough

> Complete guide to installing NixOS on a new machine using this flake.
>
> This covers the full journey: from creating the host configuration, building the install ISO, running disko to partition disks, setting up secrets with sops-nix, enrolling TPM2 for LUKS auto-unlock, and establishing remote access.
>
> **Example host**: `server` (MSI B550 Tomahawk, headless server). The same pattern applies to any new machine — adapt disk paths, hostname, and hardware config.

---

## What you're building

This is a **declarative, reproducible NixOS system** with the following properties:

| Feature | How it's implemented |
|---------|----------------------|
| **Declarative disks** | `disko` — one command partitions, formats, and mounts everything |
| **Full-disk encryption** | LUKS on the system disk, with optional TPM2 auto-unlock |
| **Ephemeral root** | `/` is tmpfs (impermanence) — reboot wipes root, state lives on `/persist` |
| **Atomic secrets** | `sops-nix` — encrypted secrets in git, decrypted at boot |
| **Remote management** | SSH with key-only auth, managed from your workstation |
| **Reproducible config** | Everything in the flake — rebuild any time, same result |

**Two-machine workflow**:

- **xps** (workstation): Edit config → `nix fmt` → commit → push to GitHub
- **server** (new machine): `git pull` → `sudo nixos-rebuild switch --flake .#server`

---

## Prerequisites

Before starting, ensure:

1. **Host config directory exists**: `hosts/<hostname>/` with at minimum:
   - `disko.nix` — disk layout (check device paths!)
   - `hardware-configuration.nix` — `nixos-generate-config` output
   - `configuration.nix` — host-specific settings

2. **sops is set up**: The `secrets/secrets.yaml` file contains at least:
   - `user-password` — the `cookiegigi` user's password hash
   - Your age public key is in `.sops.yaml` as a recipient

3. **You have the age private key**: Either:
   - Primary: `/persist/var/lib/sops-nix/key.txt` on your xps
   - Backup: Stored in Proton Pass (or your password manager)

4. **The flake builds**: On your xps, verify:
   ```bash
   cd ~/nixos
   nix flake check
   ```

5. **Flake is pushed to origin/main**: The installer will clone from GitHub.

---

## Phase 1: Create the host configuration (on xps)

If this is a brand new host, you need to create its configuration first.

### 1a. Create the host directory

```bash
cd ~/nixos
mkdir -p hosts/<hostname>
```

### 1b. Create `disko.nix`

This is the most critical file. **Triple-check the device paths** (`/dev/nvme0n1`, `/dev/sda`, etc.) — disko will erase whatever you point it at.

Example for the server (adapt as needed):

```nix
{
  disko.devices = {
    disk = {
      # NVMe - Boot, OS, Nix Store
      main = {
        type = "disk";
        device = "/dev/nvme0n1";  # <-- VERIFY THIS
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cookieluks";
                settings = {allowDiscards = true;};
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "/@persist" = {
                      mountOptions = ["compress=zstd:1" "noatime"];
                      mountpoint = "/persist";
                    };
                    "/@data" = {
                      mountOptions = ["compress=zstd:1" "noatime"];
                      mountpoint = "/data";
                    };
                    "/@nix" = {
                      mountOptions = ["compress=zstd:1" "noatime"];
                      mountpoint = "/nix";
                    };
                    "/@snapshots" = {};
                  };
                };
              };
            };
          };
        };
      };

      # Optional: additional disk for media/backup
      media = {
        type = "disk";
        device = "/dev/sda";  # <-- VERIFY THIS
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "btrfs";
                subvolumes = {
                  "/@media" = {
                    mountOptions = ["compress=lzo" "noatime"];
                    mountpoint = "/media";
                  };
                  "/@backup" = {
                    mountOptions = ["compress=lzo" "noatime"];
                    mountpoint = "/backup";
                  };
                  "/@downloads" = {
                    mountOptions = ["compress=lzo" "noatime"];
                    mountpoint = "/downloads";
                  };
                };
              };
            };
          };
        };
      };
    };

    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = ["size=4G" "mode=755"];
      };
    };
  };
}
```

> **Mountpoint shadowing gotcha**: Each subvolume's `mountpoint` must be unique. We previously had `@data` mounting to `/persist` (shadowing `@persist`) and `@backup` mounting to `/media` (shadowing `@media`). Ensure each mountpoint is distinct.

### 1c. Generate `hardware-configuration.nix`

On the target machine (from a live environment or another Linux):

```bash
sudo nixos-generate-config --root /mnt
# Then copy /mnt/etc/nixos/hardware-configuration.nix to your flake
```

Or manually create it based on `nixos-generate-config` output. Key things to verify:
- `boot.initrd.availableKernelModules` includes storage drivers (`nvme`, `sd_mod`, `ahci`, etc.)
- `hardware.cpu.amd.updateMicrocode` (for AMD) or `hardware.cpu.intel.updateMicrocode` (for Intel)
- `nixpkgs.hostPlatform` matches your architecture

### 1d. Create `configuration.nix`

Minimal host-specific configuration:

```nix
{...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  networking.hostName = "<hostname>";
  networking.domain = "cookiegigi.com";

  system.stateVersion = "25.11";  # Set to current NixOS version
}
```

### 1e. Add the host to `flake.nix`

In `flake.nix`, add a new `nixosConfigurations.<hostname>` entry. Copy the `server` config as a template:

```nix
<hostname> = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {inherit nixvim;};
  modules = [
    ./hosts/<hostname>/configuration.nix
    impermanence.nixosModules.impermanence
    disko.nixosModules.disko
    home-manager.nixosModules.home-manager
    # Add hardware-specific modules from nixos-hardware if available
    sops-nix.nixosModules.sops
    ./modules/sops.nix
    ./modules/core.nix
    ./modules/tpm.nix          # Skip for desktop/laptop if not needed
    ./modules/clipboard/xclip.nix
    ./modules/clipboard/wclip.nix
    ./modules/bluetooth.nix
    ./modules/localization/frenglish.nix
    ./modules/programs/programs.nix
    ./modules/users/cookiegigi.nix
    ./modules/home/default-server.nix  # Or default.nix for desktop
    ./modules/services.nix
  ];
};
```

### 1f. Build and test

```bash
cd ~/nixos
nix fmt
nix flake check
# Verify the new host evaluates:
nixos-rebuild build --flake .#<hostname>
```

Commit and push:

```bash
git add -A
git commit -m "feat: add <hostname> host configuration"
git push
```

---

## Phase 2: Build the install ISO (on xps)

```bash
cd ~/nixos
nix build .#nixosConfigurations.<hostname>-iso.config.system.build.isoImage
```

This creates an ISO that:
- Boots a minimal NixOS environment
- Includes the disko module (for partitioning)
- Has the same kernel/modules as your target config

Flash to USB:

```bash
# Find your USB device (BE CAREFUL)
lsblk

# Example: /dev/sdX (replace X with actual letter)
sudo dd if=result/iso/nixos-*.iso of=/dev/sdX bs=4M status=progress
sync
```

> **ISO flakes gotcha**: The minimal ISO may not have flakes enabled. If you get `experimental-feature nix-command is disabled` errors on the installer, either:
> 1. Add `nix.settings.experimental-features = ["nix-command" "flakes"];` to `modules/iso.nix` before building, OR
> 2. Fix it at runtime with: `echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf`

---

## Phase 3: Install (on target machine)

### 3a. Boot the ISO

Insert USB, boot from it, wait for the console login prompt.

The minimal ISO boots to root with empty password.

### 3b. Initial setup

**Network** (ethernet should work via DHCP):

```bash
ping nixos.org
```

**Keyboard** (if non-US layout):

```bash
loadkeys fr  # or your layout
```

> **LUKS passphrase gotcha**: The passphrase you create during disko will be needed at every boot until TPM is enrolled. The initrd console uses a US keyboard layout by default (unless your config sets `console.earlySetup = true`). Pick a passphrase using only characters that are the same in US and your layout, or be prepared to translate.

**Enable flakes** (if needed):

```bash
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
```

### 3c. Verify disk paths

```bash
lsblk
```

Confirm the device names match `disko.nix`. If they don't, **abort** and edit the file on your xps, rebuild the ISO, and start over.

### 3d. Clone the flake

```bash
git clone https://github.com/CookieGigi/nixos.git
cd nixos
```

If `git` is not available:

```bash
nix shell nixpkgs#git
```

### 3e. Partition with disko

**This destroys all data on the target disks.**

```bash
sudo nix run .#disko -- --mode disko ./hosts/<hostname>/disko.nix
```

You'll be prompted for the LUKS passphrase. This is the encryption key for your system disk.

Disko will:
1. Create GPT partition tables
2. Create EFI partition (`/boot`)
3. Create LUKS container (`cookieluks`)
4. Create BTRFS subvolumes
5. Mount everything under `/mnt`

### 3f. Copy the sops age key — **CRITICAL**

Without this, `sops-nix` cannot decrypt secrets, and the `cookiegigi` user will have no password.

**Option 1: Type it manually**

```bash
sudo mkdir -p /mnt/persist/var/lib/sops-nix
sudo nano /mnt/persist/var/lib/sops-nix/key.txt
sudo chmod 600 /mnt/persist/var/lib/sops-nix/key.txt
```

**Option 2: Copy via SSH from xps** (recommended, avoids typing a long key)

On the installer, start sshd:

```bash
passwd                    # Set a temporary root password
systemctl start sshd
ip a                      # Note the IP address
```

From the xps:

```bash
# Create directory on target
ssh root@<installer-ip> "mkdir -p /mnt/persist/var/lib/sops-nix"

# Copy the age key
sudo cat /persist/var/lib/sops-nix/key.txt | ssh root@<installer-ip> \
  "cat > /mnt/persist/var/lib/sops-nix/key.txt && chmod 600 /mnt/persist/var/lib/sops-nix/key.txt"
```

### 3g. Install NixOS

```bash
sudo nixos-install --flake .#<hostname> --no-root-passwd
```

- `--no-root-passwd`: Skips setting a root password (we use `cookiegigi` + sudo)
- The `cookiegigi` user's password comes from `sops.secrets."user-password"` (decrypted at activation)

### 3h. Reboot

```bash
reboot
```

Remove the USB drive when prompted.

At the LUKS prompt, enter the passphrase you set during disko.

Log in as `cookiegigi` with the password from your secrets.

---

## Phase 4: Post-install configuration (on target machine)

### 4a. Clone the flake locally

```bash
git clone https://github.com/CookieGigi/nixos.git ~/nixos
```

This lives on `/persist` (via `home.persistence` in `modules/home/cookiegigi/persistence-server.nix`), so it survives reboots.

### 4b. TPM2 auto-unlock (for headless/server machines)

`modules/tpm.nix` is already imported by the config, but the TPM is not yet enrolled into the LUKS slot.

**Check TPM is available** (if not, enable **fTPM** in BIOS):

```bash
sudo systemd-cryptenroll --tpm2-device=list
```

**Enroll the TPM**:

```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 \
  /dev/disk/by-partlabel/disk-main-luks
```

- `pcrs=7`: Binds to Secure Boot state (stable across firmware updates)
- The existing passphrase remains as a fallback

**Test it**:

```bash
reboot
```

If configured correctly, the system boots without prompting for the LUKS passphrase.

### 4c. Configure SSH server

For headless machines, add to `hosts/<hostname>/configuration.nix`:

```nix
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };
};

users.users.cookiegigi.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDANNAAqC6VheKXQRqV1Nw8XUznTgzPpdmE43/ZRC27g cookiegigi@cookiegigi.com"
];
```

Public keys are **not secrets** — safe to commit. Only the private key (`~/.ssh/id_ed25519` on xps) must stay secret.

Apply on the target machine:

```bash
cd ~/nixos
git pull
sudo nixos-rebuild switch --flake .#<hostname>
```

### 4d. Configure SSH client (on xps)

Add to `hosts/xps/ssh.nix` (or equivalent):

```nix
programs.ssh.extraConfig = ''
  Host <hostname>
    Hostname <ip-address>
    Port 22
    User cookiegigi
'';
```

Then test:

```bash
ssh <hostname>
```

> **known_hosts gotcha**: If you previously SSH'd into the *installer* at this IP, your `known_hosts` contains the ISO's throwaway key. You'll get a `HOST KEY HAS CHANGED` warning. Fix with:
> ```bash
> ssh-keygen -R <ip-address>
> ```

---

## Phase 5: Ongoing workflow

### Making changes

1. **Edit on xps**: Make config changes in `~/nixos`
2. **Format and check**: `nix fmt && nix flake check`
3. **Commit and push**: `git commit` → `git push`
4. **Apply on target**: `cd ~/nixos && git pull && sudo nixos-rebuild switch --flake .#<hostname>`

### What persists across reboots

Because `/` is tmpfs (impermanence), only explicitly declared paths survive:

**System-level** (`modules/core.nix` + `modules/sops.nix`):
- `/persist` — the persistent BTRFS subvolume
- `/etc/NetworkManager/system-connections`
- `/etc/ssh` — host SSH keys
- `/var/lib/nixos` — user/group IDs
- `/var/lib/sops-nix` — age key

**User-level** (`modules/home/cookiegigi/persistence-server.nix`):
- `~/.ssh` — SSH keys and config
- `~/nixos` — this repository
- `~/.local/share/keyrings` — GNOME Keyring (for Proton Pass CLI)
- `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim` — Neovim state

### Adding secrets

1. Edit `secrets/secrets.yaml` with `sops`:
   ```bash
   nix run .#edit-secrets
   # or manually:
   SOPS_AGE_KEY_FILE=/persist/var/lib/sops-nix/key.txt sops secrets/secrets.yaml
   ```

2. Add the secret declaration in `modules/sops.nix`:
   ```nix
   sops.secrets."my-new-secret" = {
     # neededForUsers = true;  # if needed during user creation
   };
   ```

3. Use it in config:
   ```nix
   config.services.someService.passwordFile = config.sops.secrets."my-new-secret".path;
   ```

4. Commit, push, and rebuild.

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `nix-command` disabled on ISO | Minimal ISO doesn't enable flakes by default | Add `nix.settings.experimental-features = ["nix-command" "flakes"];` to `modules/iso.nix` before building, or run `echo "experimental-features = nix-command flakes" \| sudo tee -a /etc/nix/nix.conf` on the installer |
| sops fails during `nixos-install` | Age key missing or wrong | Ensure `/mnt/persist/var/lib/sops-nix/key.txt` exists and contains a valid key listed in `.sops.yaml` |
| LUKS passphrase doesn't work at boot | Keyboard layout mismatch | Initrd console uses US layout. Try typing as if on QWERTY, or use only characters identical in both layouts |
| TPM not detected | fTPM/PTT disabled in BIOS | Enable **fTPM** (AMD) or **Intel PTT** in BIOS security settings |
| `known_hosts` mismatch | ISO key vs installed system key | `ssh-keygen -R <ip>` to remove old entry |
| `cookiegigi` user missing after install | `hashedPasswordFile` points to non-existent secret | Check `sops.secrets."user-password".neededForUsers = true;` is set |
| Disko wipes wrong disk | Wrong device path in `disko.nix` | **Always** `lsblk` before running disko. Device names can change between boots |

---

## Reference

### Key files

| File | Purpose |
|------|---------|
| `hosts/<hostname>/disko.nix` | Declarative disk partitioning (LUKS + BTRFS) |
| `hosts/<hostname>/hardware-configuration.nix` | Kernel modules, generated by `nixos-generate-config` |
| `hosts/<hostname>/configuration.nix` | Host-specific NixOS config |
| `modules/sops.nix` | sops-nix activation + secret definitions |
| `modules/tpm.nix` | TPM2 initrd modules + LUKS unlock config |
| `modules/core.nix` | Bootloader, networking, impermanence base config |
| `modules/iso.nix` | ISO-specific overrides |
| `modules/users/cookiegigi.nix` | User account definition |
| `modules/home/cookiegigi/persistence-server.nix` | Home directory persistence rules |
| `secrets/secrets.yaml` | Encrypted secrets (user password, WiFi, etc.) |
| `.sops.yaml` | Age key recipients for encryption |

### Useful commands

```bash
# Check flake evaluates
nix flake check

# Build ISO
nix build .#nixosConfigurations.<hostname>-iso.config.system.build.isoImage

# Test config without switching
sudo nixos-rebuild test --flake .#<hostname>

# Check BTRFS subvolumes
btrfs subvolume list /

# Check LUKS status
sudo cryptsetup status cookieluks

# Check TPM enrollment
sudo systemd-cryptenroll /dev/disk/by-partlabel/disk-main-luks

# View decrypted secrets (for debugging)
sudo cat /run/secrets/user-password
```

---

## See also

- [`docs/sops-nix.md`](./sops-nix.md) — Managing secrets with sops-nix
- [`docs/home-manager.md`](./home-manager.md) — Home-manager setup
- [NixOS Manual — Installation](https://nixos.org/manual/nixos/stable/#sec-installation)
- [disko documentation](https://github.com/nix-community/disko)
- [sops-nix documentation](https://github.com/Mic92/sops-nix)
