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
  - `~/.password-store` — encrypted secrets (`0700`)
  - `~/.gnupg` — GPG key and trust database (`0700`, required: GnuPG
    refuses a group/world-readable homedir)

### One-time setup

```sh
# 1. Create a GPG key (choose a passphrase, or none: the disk is LUKS-encrypted)
gpg --full-generate-key

# 2. Initialise the store with that key
pass init <KEY_ID or email>

# 3. Store the mail password
pass insert mail/<account>
```

`pass insert` prompts **twice** (`Enter password`, then `Retype password`) and
uses `read -s`, so nothing echoes while you type or paste — that is normal, not
a hang. Use `pass insert --echo mail/<account>` if you want visible feedback.
No pinentry window appears on insert: encryption only needs the public key.
Pinentry shows up on `pass show`, i.e. when the password is actually decrypted.

### Point himalaya at pass

First run of `himalaya-tui` opens the account wizard (server discovery,
authentication test). When it asks for the password, choose the **custom
command** option and enter:

```
pass show mail/<account>
```

The wizard writes the result into `~/.config/himalaya/config.toml`. A working
Posteo account looks like this:

```toml
[accounts.posteo]
default = true

email = "user@posteo.com"

imap.server = "imaps://posteo.de:993"
imap.sasl.plain.authcid = "user@posteo.com"
imap.sasl.plain.passwd.command = ["pass", "show", "mail/posteo"]

smtp.server = "smtps://posteo.de:465"
smtp.sasl.plain.authcid = "user@posteo.com"
smtp.sasl.plain.passwd.command = ["pass", "show", "mail/posteo"]

mailbox.alias.inbox = "INBOX"
```

Things that are easy to get wrong:

- **Scheme, not just host:** use `imaps://` / `smtps://` for implicit TLS on
  ports 993 / 465. Plain `imap://` with STARTTLS does not work against Posteo.
- **`authcid`, not `username`**, and **`passwd.command`, not `password.command`**
  — the wizard emits the v2 schema.
- **The command is an array** (`["pass", "show", "..."]`). A bare shell string
  is not executed.
- `sasl.plain` is correct even if the wizard's SASL selector was set to
  `LOGIN`: both are username+password over TLS.

If the wizard stored `passwd.raw` (or `password.raw` in older versions)
instead, replace it with the `command` form above — never leave a plaintext
password in the config.

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

> **No OpenPGP:** neither `himalaya-tui` 0.1.0 nor `himalaya` v2 implements
> OpenPGP (v2 dropped it in the rewrite), so inbound-encrypted mail is
> unreadable here. Use `neomutt` for encrypted mail — see `docs/neomutt.md`.

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
