# himalaya-tui

Terminal email client (TUI) from the Pimalaya project. It shares a single
`config.toml` with the `himalaya` CLI (v2 schema), but is a separate binary.

- Upstream: <https://github.com/pimalaya/himalaya-tui>
- Module: `modules/home/cookiegigi/programs/himalaya.nix`
- Binary: `himalaya-tui`

## Why a flake input?

`himalaya-tui` is `v0.x`, has no tagged releases, and is **not in nixpkgs**.
The upstream repo ships a flake exposing `packages.<system>.default`, so the
config consumes it directly:

```nix
himalaya-tui = {
  url = "github:pimalaya/himalaya-tui";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";
};
```

It builds from source with the fenix Rust toolchain, so it is not substituted
from cache: the first build takes a while. Update with:

```sh
nix flake lock --update-input himalaya-tui
```

Remove the input again once nixpkgs carries the package.

## Password strategy: pass

The module installs and configures `pass` (password-store) + GnuPG:

- `programs.password-store.enable = true` → the `pass` command.
- `programs.gpg.enable = true`, `services.gpg-agent.enable = true` with
  `pinentry-qt`. A GUI pinentry is used on purpose: `himalaya-tui` owns the
  terminal, so `pinentry-curses` would fight the TUI for it. The Qt pinentry
  talks Wayland natively.
- Persistent paths (on top of the LUKS volume):
  - `~/.config/himalaya` — wizard-written account config
  - `~/.password-store` — encrypted secrets
  - `~/.gnupg` — GPG key and trust database

### One-time setup

```sh
# 1. Create a GPG key (choose a passphrase, or none: the disk is LUKS-encrypted)
gpg --full-generate-key

# 2. Initialise the store with that key
pass init <KEY_ID or email>

# 3. Store the mail password
pass insert mail/<account>
```

### Point himalaya at pass

First run of `himalaya-tui` opens the account wizard (server discovery,
authentication test). When it asks for the password, choose the **custom
command** option and enter:

```
pass show mail/<account>
```

The wizard writes that as `password.command` (a shell command) into
`~/.config/himalaya/config.toml`, e.g.:

```toml
[accounts.example]
default = true
from = "user@example.com"

imap.server = "imap.example.com"
imap.sasl.plain.username = "user@example.com"
imap.sasl.plain.password.command = "pass show mail/example"

smtp.server = "smtp.example.com"
smtp.sasl.plain.username = "user@example.com"
smtp.sasl.plain.password.command = "pass show mail/example"
```

If the wizard stored `password.raw` instead, replace each `raw` key with the
`command` form above — never leave a plaintext password in the config.

Any shell command works, so another password manager can be swapped in
without touching this module.

## Usage

```sh
himalaya-tui                 # default account
himalaya-tui -a <account>    # pick an account
himalaya-tui --no-config     # wizard, without reading config.toml
```

The TUI writes no local mail cache, so only the three paths above need to
persist.

> **First-switch gotcha:** the bind mounts for these paths are created by this
> rebuild. Home Manager activation can run before the new mount units are up,
> so `~/.gnupg/gpg.conf` / `gpg-agent.conf` land *under* the mount and appear
> missing until the next boot, and `gpg-agent` falls back to the store-path
> pinentry. Fix without rebooting by re-running activation:
>
> ```sh
> sudo systemctl restart home-manager-cookiegigi.service
> ```
>
> (or simply reboot once). `ls -la ~/.gnupg` should show `gpg.conf` and
> `gpg-agent.conf` symlinks.

## Rebuild

```sh
sudo nixos-rebuild switch --flake .#xps
```
