# Server Hardening Plan

> **Date:** 2026-07-18
> **Host:** `server` (MSI B550, x86_64-linux)
> **Goal:** AI inference, media streaming, backup orchestration, and self-hosted services.

> **Last updated:** 2026-07-18 — Phase 1 completed and committed (`2d9f243`).
> Repository was restructured into role-based directories (`modules/common/`, `modules/desktop/`, `modules/server/`) before hardening.

---

## 1. Current State Assessment

### What's Good (Keep)

| Area | Status | Notes |
|---|---|---|
| **Disk encryption** | ✅ | LUKS on NVMe + TPM2 auto-unlock via `tpm.nix` |
| **Ephemeral root** | ✅ | `tmpfs` root + BTRFS persistence via impermanence |
| **Secrets** | ✅ | sops-nix with age key on `/persist` |
| **SSH auth** | ✅ | Password and KbdInteractive disabled, ed25519 key only |
| **Disk layout** | ✅ | NVMe for OS/Nix, SATA HDD for media/backup/downloads |
| **User model** | ✅ | Single admin user (`cookiegigi`), password hash in sops |
| **Declarative disks** | ✅ | Disko layout is clean and maintainable |
| **Home-manager** | ✅ | Correctly CLI-only (`default-server.nix` — no GUI apps) |

### Corrected Understanding: What Is NOT Inherited

The server configuration in `flake.nix` **does NOT** import the laptop's desktop stack. These modules are **only on the `xps` laptop**:

- ❌ `niri.nix` (Wayland compositor)
- ❌ `audio.nix`
- ❌ `wifi-home.nix`
- ❌ Desktop GUI apps (`firefox`, `chromium`, `heroic`, `tidal`, `quickshell`)

The server is already headless and CLI-only by default.

### What Is Wrong

#### 1. Three laptop modules are dead weight ✅ FIXED

- ~~`clipboard/xclip.nix`~~ — moved to `modules/desktop/`; server role no longer imports it.
- ~~`clipboard/wclip.nix`~~ — moved to `modules/desktop/`; server role no longer imports it.
- ~~`bluetooth.nix`~~ — moved to `modules/desktop/`; server role no longer imports it.

#### 2. `core.nix` leaks three laptop-specific settings ✅ FIXED

Restructured into role-based directories. `core.nix` is now host-agnostic in `modules/common/`; laptop assumptions live in `modules/desktop/core-desktop.nix`:

- ~~`services.upower.enable = true`~~ — removed from common `core.nix`, now only in `desktop/core-desktop.nix`.
- ~~`hardware.graphics.enable32Bit = true`~~ — removed from common `core.nix`, now only in `desktop/core-desktop.nix`.
- ~~`networking.networkmanager.enable = true`~~ — removed from common `core.nix`; server uses `systemd-networkd` via `modules/server/core-server.nix`.

> **Note:** `hardware.graphics.enable = true` (64-bit, **not** `enable32Bit`) may be wanted later for AI/compute (CUDA/ROCm), but that is a separate concern.

#### 3. No firewall ✅ FIXED

`networking.firewall.enable = true` and `allowPing = true` are now set in `modules/server/security.nix`. Service-specific modules (e.g. `media.nix`) will open ports explicitly.

#### 4. SSH is only minimally hardened ✅ FIXED

Now in `modules/server/security.nix`:

- ✅ `PasswordAuthentication = false`
- ✅ `KbdInteractiveAuthentication = false`
- ✅ `PermitRootLogin = "no"`
- ✅ `AllowUsers = ["cookiegigi"]`
- ✅ `MaxAuthTries = 3`
- ✅ `ClientAliveInterval = 300` / `ClientAliveCountMax = 2`
- ✅ `X11Forwarding = false`
- ✅ `LogLevel = "VERBOSE"`

#### 5. No intrusion detection / brute-force protection ✅ FIXED (partial)

- ✅ `fail2ban` enabled in `modules/server/security.nix` (`sshd` jail, systemd backend, incremental bans).
- ❌ No `auditd`.
- ✅ SSH rate limiting via fail2ban.

#### 6. No kernel / sysctl hardening ✅ FIXED

`modules/server/security.nix` now sets:

- ✅ Disable IP source routing.
- ✅ Disable ICMP redirects.
- ✅ Enable SYN cookies.
- ✅ Restrict `ptrace` (`kernel.yama.ptrace_scope = 3`).
- ✅ Disable core dumps (`fs.suid_dumpable = 0`).
- ✅ Strict ASLR (`kernel.randomize_va_space = 3`).

#### 7. No container runtime ✅ FIXED

For AI / media / self-hosting, a declarative container story is needed. Currently zero configuration for Podman or Docker.

#### 8. No services for the stated goals

The server is an empty shell. It has no:

- **AI:** Ollama, CUDA/ROCm setup, or inference API.
- **Media:** Jellyfin, *arr stack, or Samba/NFS shares for `/media`.
- **Backup:** Restic, Borg, or automated BTRFS snapshots (Sanoid).
- **Reverse proxy:** Caddy, Traefik, or Nginx for ingress and TLS.
- **Remote access:** Tailscale, WireGuard, or SSH tunnel alternative.
- **Auth/SSO:** Authelia, Authentik, or basic proxy auth.

#### 9. SATA HDD is unencrypted

The NVMe OS disk is LUKS-encrypted with TPM unlock. The SATA HDD (`/dev/sda`) holding `/media`, `/backup`, and `/downloads` is **plain BTRFS** with no encryption. If the server is stolen or the drive is removed, those volumes are readable. This may be acceptable for media (movies, music) but is a concern if `/backup` contains personal data.

---

## 2. Hardening Plan (Phased)

### Phase 1: Strip Laptop Residue + Harden Core ✅ DONE

**Goal:** Remove dead weight, harden SSH/network/kernel, add container runtime.

#### A. Remove laptop modules from server ✅

Restructured into role-based directories. Desktop modules (`clipboard/*`, `bluetooth`, `audio`, `wifi-home`, `niri`) live in `modules/desktop/` and are only imported by the `xps` host.

#### B. Fix `core.nix` laptop leaks ✅

Instead of `mkForce` overrides, `core.nix` was made host-agnostic in `modules/common/core.nix`. Laptop-specific settings moved to `modules/desktop/core-desktop.nix`:

- `services.upower.enable = true`
- `hardware.graphics.enable32Bit = true`
- `networking.networkmanager.enable = true`

Server gets clean defaults via `modules/server/core-server.nix`:
- `networking.networkmanager.enable = false;`
- `networking.useNetworkd = true;`

#### C. Create `modules/server/security.nix` ✅

Implemented with:
- **Firewall:** `enable = true`, `allowPing = true`
- **SSH hardening:** `PermitRootLogin = "no"`, `AllowUsers = ["cookiegigi"]`, `MaxAuthTries = 3`, `ClientAliveInterval = 300`, `X11Forwarding = false`, `LogLevel = "VERBOSE"`
- **Fail2ban:** `sshd` jail, systemd backend, incremental bans (1h → 1w), persistence via `/var/lib/fail2ban`
- **Sysctl:** source routing off, ICMP redirects off, SYN cookies on, `ptrace_scope = 3`, no core dumps, ASLR = 3

#### D. Create `modules/server/containers.nix` ✅

- Rootless Podman (`virtualisation.podman.enable = true`)
- Docker socket compatibility (`dockerSocket.enable = true`)
- `podman-compose` in system packages

### Phase 2: Service Architecture

**Goal:** Build the AI, media, backup, and self-hosting stack.

**Open questions before implementation:**

1. **GPU:** What card is in this machine? (NVIDIA / AMD / Intel?) This determines AI container and compute setup.
2. **Internet exposure:** Will this server be directly reachable from the internet (port forwarding), or only via VPN/Tailscale?
3. **Domains:** Do you plan to use `*.cookiegigi.com` subdomains with reverse proxy + Let's Encrypt, or local IPs only?
4. **Backup destination:** Where should backups go? (S3, B2, another server, external disk?)

#### Proposed modules (pending answers above):

| Goal | Module | Technology |
|---|---|---|
| **Reverse Proxy** | `modules/server/reverse-proxy.nix` | **Caddy** — automatic HTTPS via ACME, dead-simple config. Traefik is an alternative if Docker labels are preferred. |
| **AI** | `modules/server/ai.nix` | **Ollama** — run as rootless Podman container. GPU passthrough depends on card (NVIDIA needs `nvidia-container-toolkit`; AMD is easier via ROCm). |
| **Media** | `modules/server/media.nix` | **Jellyfin** — containerized, bind-mount `/media` from SATA HDD. |
| **Backup** | `modules/server/backup.nix` | **Restic** (offsite/cloud) + **Sanoid** (local BTRFS snapshots on `/data`, `/media`, `/backup`). |
| **Remote Access** | `modules/server/vpn.nix` | **Tailscale** or **WireGuard** — avoid exposing SSH directly to the internet. Tailscale is zero-config mesh VPN. |
| **Auth Gate** | `modules/server/auth.nix` | **Authelia** — protect self-hosted services with 2FA behind the reverse proxy. |

### Phase 3: Optional Deeper Hardening

- **HDD encryption:** Consider LUKS on the SATA HDD if `/backup` contains sensitive data.
- **Automatic updates:** `system.autoUpgrade` with a scheduled reboot window, since the server tracks `linuxPackages_latest`.
- **Auditd:** Enable `security.auditd.enable = true` for syscall forensics.
- **User namespaces:** Consider `kernel.unprivileged_userns_clone = 0` for stricter sandboxing, but test first as it may break some container workloads.

---

## 3. Files to Create / Modify

### Phase 1 Files (New)

| File | Purpose | Status |
|---|---|---|
| `modules/server/security.nix` | Firewall, SSH hardening, fail2ban, sysctl | ✅ Done |
| `modules/server/containers.nix` | Rootless Podman + Docker socket compat | ✅ Done |
| `modules/server/core-server.nix` | Server networking (systemd-networkd, no upower) | ✅ Done |
| `modules/desktop/core-desktop.nix` | Desktop settings (upower, networkmanager, enable32Bit) | ✅ Done |
| `modules/common/default.nix` | Universal module aggregator | ✅ Done |
| `modules/desktop/default.nix` | Desktop role aggregator | ✅ Done |
| `modules/server/default.nix` | Server role aggregator | ✅ Done |

### Phase 1 Files (Modify)

| File | Change | Status |
|---|---|---|
| `flake.nix` | Remove explicit per-host import lists; use role aggregators | ✅ Done |
| `hosts/xps/configuration.nix` | Import `modules/desktop` role | ✅ Done |
| `hosts/server/configuration.nix` | Import `modules/server` role; extract SSH to `ssh.nix` | ✅ Done |
| `modules/common/core.nix` | Remove laptop-specific settings (upower, networkmanager, enable32Bit) | ✅ Done |

### Phase 2 Files (New — pending open questions)

| File | Purpose |
|---|---|
| `modules/server/reverse-proxy.nix` | Caddy ingress |
| `modules/server/ai.nix` | Ollama / inference |
| `modules/server/media.nix` | Jellyfin |
| `modules/server/backup.nix` | Restic + Sanoid |
| `modules/server/vpn.nix` | Tailscale / WireGuard |
| `modules/server/auth.nix` | Authelia |

---

## 4. Checklist

### Phase 1 ✅ DONE

- [x] Remove `clipboard/xclip.nix`, `clipboard/wclip.nix`, `bluetooth.nix` from server flake (restructured into `modules/desktop/`)
- [x] Fix `core.nix` laptop leaks (made host-agnostic; desktop settings moved to `core-desktop.nix`)
- [x] Create `modules/server/core-server.nix`
- [x] Create `modules/server/security.nix`
- [x] Create `modules/server/containers.nix`
- [x] Update `flake.nix` imports (role-based aggregators)
- [x] Run `nix fmt`
- [x] Run `nix flake check`
- [x] Run `nix build .#nixosConfigurations.server.config.system.build.toplevel`

### Phase 2 PENDING

- [ ] Answer open questions (GPU, exposure, domains, backup target)
- [ ] Implement Phase 2 modules (reverse-proxy, ai, media, backup, vpn, auth)

### Phase 3 PENDING

- [ ] Consider HDD encryption
- [ ] Consider automatic updates
- [ ] Consider `auditd`
- [ ] Consider `kernel.unprivileged_userns_clone = 0`
