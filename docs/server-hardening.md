# Server Hardening Plan

> **Date:** 2026-07-18
> **Host:** `server` (MSI B550, x86_64-linux)
> **Goal:** AI inference, media streaming, backup orchestration, and self-hosted services.

> **Last updated:** 2026-07-19 — Phase 1 completed. `nvidia.nix` implemented and built successfully (headless, open GA102 modules, no container toolkit).
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

**Answers (2026-07-18):**

| # | Question | Answer |
|---|---|---|
| 1 | GPU | **NVIDIA RTX 3080 Ti 12 GB** (GA102, PCI `10DE:2208`). Currently on open-source `nouveau` driver; proprietary driver needed for CUDA/NVENC. |
| 2 | Exposure | **LAN-only for now.** No port forwarding, no public ingress. |
| 3 | Domains | **Public `*.cookiegigi.com` subdomains with a *local* CA** (Caddy `tls internal`). Split-horizon DNS, not public ACME. |
| 4 | Backup target | **The local `/backup` partition** on the SATA HDD. |

#### SSH Recon Findings (from `server.home`)

- **CPU:** AMD, 16 threads
- **RAM:** 15 GiB
- **Internet:** Working (HTTP 200 from cache.nixos.org)
- **IPv6 note:** The server holds a global IPv6 address (`2a01:cb19:...`). Port 22 is currently open to all interfaces via `services.openssh.openFirewall`; on IPv6 without NAT this may be internet-reachable depending on the router firewall.

#### Corrections to the original plan

1. **Sanoid is ZFS-only** — it cannot snapshot BTRFS. For BTRFS local snapshots, use **btrbk** or **snapper**.
2. **Backup encryption leak:** `/persist` and `/data` are LUKS-encrypted, but `/backup` lives on the **unencrypted** SATA HDD. Plaintext snapshots (btrbk) of `/persist` → `/backup` would silently undo disk-encryption. **Restic encrypts its repository client-side** — this tips the backup recommendation toward Restic for sensitive volumes.

#### Proposed modules (reviewed):

| Goal | Module | Technology | Status |
|---|---|---|---|
| **GPU driver** | `modules/server/nvidia.nix` | Proprietary NVIDIA driver (modesetting + open GA102 modules), `nvidia-smi` | **Build first** |
| **Reverse Proxy** | `modules/server/reverse-proxy.nix` | **Caddy** with `tls internal` (local CA, no ACME, no public exposure) | Build |
| **AI** | `modules/server/ai.nix` | **Ollama** native NixOS service (`services.ollama`, `acceleration = "cuda"`), not containerized | Build |
| **Media** | `modules/server/media.nix` | **Jellyfin** native NixOS service (`services.jellyfin`), behind Caddy | Build |
| **Backup** | `modules/server/backup.nix` | **Restic** encrypted repo on `/backup/restic`; optional **btrbk** local snapshots | Build |
| **Remote Access** | `modules/server/vpn.nix` | **Tailscale** — add only when remote access is needed | Deferred |
| **Auth Gate** | `modules/server/auth.nix` | **Authelia** — add only when services are exposed publicly | Deferred |

> **Rationale for deferring Tailscale & Authelia:** LAN-only means there is no external attack surface for these to mitigate. Tailscale is a 5-line module to add later; Authelia adds significant identity-backend complexity that buys nothing on a trusted LAN with one user.

#### Phase 2 Decision Points (awaiting user go-ahead)

| # | Decision | Recommendation |
|---|---|---|
| 1 | Ollama: native NixOS service vs rootless Podman container? | **Native service** — nixpkgs already builds CUDA support, avoids nvidia-container-toolkit + CDI + Podman GPU passthrough complexity. |
| 2 | Jellyfin: native NixOS service vs container? | **Native service** — mature module, NVENC works out of the box with the NVIDIA driver. |
| 3 | DNS for `*.cookiegigi.com`: `networking.extraHosts` on xps vs local DNS server? | **extraHosts on xps first** — zero new services, trivially declarative; migrate to local DNS later if phones/other devices need it. |
| 4 | Back up `/media` too, or only `/persist` + `/data`? | **`/persist` + `/data` only** — media is replaceable and large. |
| 5 | Restrict SSH (port 22) to LAN subnets, given global IPv6? | **Yes** — small firewall change in `security.nix` to whitelist LAN ranges. |
| 6 | Add btrbk local snapshots alongside Restic? | Optional — fast BTRFS rollback without encryption; your call. |

#### Implementation Order

1. `nvidia.nix` — driver only; first rebuild confirms `nvidia-smi` and CUDA stack.
2. `backup.nix` — protect `/persist` before services accumulate state.
3. `reverse-proxy.nix` — local CA + Caddy, plus DNS (`extraHosts`) on the xps side.
4. `media.nix` — Jellyfin behind Caddy.
5. `ai.nix` — Ollama with CUDA; may take longest to build due to CUDA closure size.
6. Update this doc with final statuses.

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

### Phase 2 Files (New — reviewed)

| File | Purpose |
|---|---|
| `modules/server/nvidia.nix` | Proprietary NVIDIA driver |
| `modules/server/reverse-proxy.nix` | Caddy ingress with local CA |
| `modules/server/ai.nix` | Ollama native service (CUDA) |
| `modules/server/media.nix` | Jellyfin native service |
| `modules/server/backup.nix` | Restic encrypted repo + optional btrbk snapshots |
| `modules/server/vpn.nix` | Tailscale (deferred) |
| `modules/server/auth.nix` | Authelia (deferred) |

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

### Phase 2 Reviewed — awaiting implementation

- [x] Answer open questions (GPU, exposure, domains, backup target)
- [x] Confirm GPU via SSH (NVIDIA GA102 / RTX 3080 Ti 12 GB)
- [x] Document corrections (Sanoid → btrbk, backup encryption leak)
- [x] Define decision points & implementation order
- [ ] **User confirmation** on the 6 decision points above
- [x] Implement `nvidia.nix` (headless, no container toolkit, open GA102 modules)
- [ ] Implement `backup.nix`
- [ ] Implement `reverse-proxy.nix`
- [ ] Implement `media.nix`
- [ ] Implement `ai.nix`
- [ ] Update DNS (`extraHosts` on xps) for `*.cookiegigi.com`
- [ ] Update this doc with final Phase 2 statuses

### Phase 3 PENDING

- [ ] Consider HDD encryption
- [ ] Consider automatic updates
- [ ] Consider `auditd`
- [ ] Consider `kernel.unprivileged_userns_clone = 0`
