# NixOS Install Walkthrough

> How to install NixOS on a new machine using this flake, from ISO creation to a remotely manageable system.
>
> Based on the `server` (MSI B550 Tomahawk) install. Adapt host name, disk paths, and hardware config for other machines.

---

## Overview

1. Build the install ISO from this flake.
2. Boot the ISO on the target machine.
3. Partition, format, and mount disks declaratively with **disko**.
4. Copy the **sops age key** so activation can decrypt the user password.
5. Run `nixos-install`.
6. Reboot, then enroll **TPM2** for headless LUKS auto-unlock.
7. Enable **SSH** and verify remote access.

---

## Prerequisites

- The target host config exists under `hosts/<host>/` (e.g. `hosts/server/`).
- `disko.nix` lists the correct disk device paths (`/dev/nvme0n1`, `/dev/sda`, etc.). **Edit before install if they differ**.
- `hardware-configuration.nix` is already generated for the target machine (or you are ready to regenerate it after install).
- The **sops age key** is accessible: either the primary key on your existing machine (`/persist/var/lib/sops-nix/key.txt`) or the backup key from Proton Pass.
- The flake is clean and pushed to `origin/main` so the installer can clone it.

---

## 1. Build the ISO

On your existing NixOS machine (xps):

```bash
cd ~/nixos
nix build .#nixosConfigurations.<host>-iso.config.system.build.isoImage
# e.g. for the server:
# nix build .#nixosConfigurations.server-iso.config.system.build.isoImage
```

Flash the resulting `.iso` to a USB drive (e.g. with `dd` or `cp`).

**Optional — fix the ISO for flakes:**

If your ISO lacks flakes (older installer or missing `nix.settings.experimental-features`), add this to `modules/iso.nix` before building:

```nix
nix.settings.experimental-features = ["nix-command" "flakes"];
```

---

## 2. Boot the ISO

Insert the USB, boot from it, and wait for the console login.

The minimal ISO has a root user with an empty password, but `sshd` is **not** started by default.

---

## 3. First steps on the installer

### Network

Ethernet (DHCP) should work out of the box:

```bash
ping nixos.org
```

### Keyboard

If your keyboard is AZERTY (or any non-US layout), set it now:

```bash
loadkeys fr
```

> **Gotcha**: the LUKS passphrase you type here is what you'll enter later at boot. The initrd console may still use a **US layout** unless `console.earlySetup = true` is set in your config. To avoid surprises, pick a passphrase using only characters that are identical in both layouts, or be ready to translate when typing at the boot prompt.

### Verify disk paths

```bash
lsblk
```

Confirm the devices match `hosts/<host>/disko.nix` (e.g. `/dev/nvme0n1` and `/dev/sda`).
If they don't, **edit the file before proceeding** — disko will erase whatever device you point it at.

### Enable flakes (if the ISO doesn't have them)

If `nix --version` or `nix run` complains about `experimental-feature nix-command is disabled`:

```bash
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
```

This also covers `nixos-install --flake` later.

---

## 4. Clone the flake

```bash
git clone https://github.com/CookieGigi/nixos.git
cd nixos
```

If `git` is missing on the minimal ISO:

```bash
nix shell nixpkgs#git
```

---

## 5. Partition, format, and mount with disko

This **destroys all data** on the target disks. It also asks you to create the LUKS passphrase.

```bash
sudo nix run .#disko -- --mode disko ./hosts/<host>/disko.nix
```

Disko will:
- create GPT partitions,
- set up LUKS (`cookieluks`),
- create BTRFS subvolumes,
- mount everything under `/mnt`.

> **Layout check**: after the `16a5082` fix, the server uses:
> - `@persist` → `/persist`
> - `@data` → `/data`
> - `@nix` → `/nix`
> - `@media` → `/media`
> - `@backup` → `/backup`
> - `@downloads` → `/downloads`

---

## 6. Copy the sops age key — **critical**

The install will fail to decrypt `user-password` if the age key is missing. Without it, the `cookiegigi` user has no password.

On the target machine (after disko mounts `/mnt`):

```bash
sudo mkdir -p /mnt/persist/var/lib/sops-nix
sudo nano /mnt/persist/var/lib/sops-nix/key.txt
sudo chmod 600 /mnt/persist/var/lib/sops-nix/key.txt
```

Paste the **primary** age private key (from `/persist/var/lib/sops-nix/key.txt` on your xps) or the **backup** key from Proton Pass. Both are valid recipients in `.sops.yaml`.

**Alternative** — copy over SSH from your xps instead of typing:

On the installer, start sshd and set a temporary root password:

```bash
passwd
systemctl start sshd
ip a    # note the IP
```

From the xps:

```bash
ssh root@<installer-ip> "mkdir -p /mnt/persist/var/lib/sops-nix"
sudo cat /persist/var/lib/sops-nix/key.txt | ssh root@<installer-ip> \
  "cat > /mnt/persist/var/lib/sops-nix/key.txt && chmod 600 /mnt/persist/var/lib/sops-nix/key.txt"
```

---

## 7. Install the system

```bash
sudo nixos-install --flake .#<host> --no-root-passwd
```

`--no-root-passwd` skips the interactive root password prompt. The `cookiegigi` user's password comes from sops (`hashedPasswordFile`).

---

## 8. Reboot

```bash
reboot
```

Remove the USB. At the LUKS prompt, type your passphrase (mind the US-layout gotcha if applicable).

Log in as `cookiegigi` with the password stored in `secrets/secrets.yaml`.

---

## 9. Post-install setup

### 9a. Clone the flake on the new machine

The repo must live at `~/nixos` (persisted via `home.persistence."/persist"` in `modules/home/cookiegigi/persistence-server.nix`):

```bash
git clone https://github.com/CookieGigi/nixos.git ~/nixos
```

### 9b. TPM2 auto-unlock (headless / server hosts)

`modules/tpm.nix` is already imported by the server config, but the TPM is not yet enrolled into the LUKS slot. Without this, every reboot requires the passphrase at the console.

Check the TPM is visible (if not, enable **fTPM** in the BIOS):

```bash
sudo systemd-cryptenroll --tpm2-device=list
```

Enroll it:

```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 \
  /dev/disk/by-partlabel/disk-main-luks
```

- PCR 7 = secure-boot state (stable across BIOS updates).
- Add `+0` if you also want to bind to the exact firmware (requires re-enrollment after firmware updates).

Then reboot: it should skip the passphrase prompt entirely.

### 9c. Enable SSH on the server

Add to `hosts/<host>/configuration.nix` (done for the server in commit `0082675`):

```nix
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };
};

users.users.cookiegigi.openssh.authorizedKeys.keys = [
  "ssh-ed25519 <your-xps-public-key>"
];
```

Public keys are **not secrets** — safe to commit in plain text. Only the private key stays on the xps.

Then on the server:

```bash
cd ~/nixos
git pull
sudo nixos-rebuild switch --flake .#<host>
```

### 9d. SSH from the xps

```bash
ssh server
```

> **Gotcha**: if you previously SSH'd into the *installer* at `192.168.1.49`, your `known_hosts` contains the ISO's throwaway key. You'll get a `HOST KEY HAS CHANGED` warning. Clear it with:
> ```bash
> ssh-keygen -R 192.168.1.49
> ```

---

## 10. Sanity checks

On the new machine:

```bash
findmnt -t btrfs,vfat       # /persist /nix /data /media /backup /downloads /boot
ip a                         # confirm the expected IP (e.g. 192.168.1.49)
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `nix-command` disabled on ISO | `echo "experimental-features = nix-command flakes" \| sudo tee -a /etc/nix/nix.conf` |
| sops fails during install | The age key at `/mnt/persist/var/lib/sops-nix/key.txt` is missing or wrong. Copy the correct one before `nixos-install`. |
| LUKS passphrase doesn't work at boot | The initrd console may use US layout. Try typing the passphrase as if the keyboard were QWERTY. |
| `known_hosts` mismatch after install | `ssh-keygen -R <IP>` to remove the ISO's old key. |
| TPM not detected | Enable **fTPM** (AMD) or **Intel PTT** in the BIOS security settings. |

---

## Reference files

| File | Purpose |
|------|---------|
| `hosts/<host>/disko.nix` | Declarative disk layout (LUKS + BTRFS) |
| `hosts/<host>/hardware-configuration.nix` | Kernel modules, generated by `nixos-generate-config` |
| `modules/sops.nix` | sops-nix activation + secret definitions |
| `modules/tpm.nix` | systemd initrd + TPM2 LUKS unlock |
| `modules/home/cookiegigi/persistence-server.nix` | What survives reboots on the server |
| `modules/iso.nix` | ISO overrides (disable systemd-boot, squashfs compression) |
| `.sops.yaml` | Age key recipients for secret encryption |

---

## Next steps after install

- Future config changes are edited on the xps, pushed to `origin/main`, and pulled on the server with `git pull && sudo nixos-rebuild switch --flake .#<host>`.
- For a desktop host (xps), the workflow is identical but skips TPM enrollment and SSH server setup (the desktop already has its own config).
