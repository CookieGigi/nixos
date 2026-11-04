# neomutt

Terminal mail client for the Posteo account, used mainly because it is the only
client on this host that can do OpenPGP.

- Upstream: <https://neomutt.org>
- Package: `pkgs.neomutt` (20260616, built with `--gpgme`)
- Module: `modules/home/cookiegigi/programs/neomutt.nix`
- Generated config: `~/.config/neomutt/neomuttrc` (store symlink, do not edit)

## Why not himalaya

Neither `himalaya-tui` 0.1.0 nor `himalaya` v2 has any OpenPGP support:

- `himalaya-tui`'s `Cargo.lock` contains no PGP crate at all, and the binary
  carries the literal error `no PGP backend available to sign or encrypt`.
- `himalaya` v2.2.1 (the version in nixpkgs) dropped PGP entirely when it was
  rewritten; its `Cargo.toml` has no `pgp` feature and no gpg dependency. PGP
  only existed in the v0.x/v1 line via `email-lib` + gpgme.

So `himalaya-tui` stays as the fast TUI for reading plain mail, and encrypted
mail goes through neomutt. Both share the same GnuPG key and the same `pass`
store.

## Shared secret material

`pass`, `gpg` and `gpg-agent` are declared in
`modules/home/cookiegigi/programs/gpg.nix` and are shared by every mail client:

| Path | Contents | Persistence |
|---|---|---|
| `~/.password-store` | mailbox passwords, encrypted to your key | `.password-store`, mode `0700` |
| `~/.gnupg` | private key, trustdb, agent config | `.gnupg`, mode `0700` |

`neomutt` never stores a password. It evaluates `pass show mail/posteo` at
connect time (`set imap_pass = "`pass show mail/posteo`"`), and `gpg-agent`
caches the decryption for `defaultCacheTtl` (1 hour), so pinentry-qt only shows
up once per hour.

Pinentry is `pinentry-qt` on purpose: neomutt owns the terminal, so
`pinentry-curses` would fight it for the screen. Qt talks Wayland directly.

## Usage

```sh
neomutt          # open INBOX
neomutt -f +Sent # open a specific folder
```

Reading encrypted mail is automatic: GPGME decrypts it, pinentry-qt asks for the
passphrase if the agent cache is cold, and the signature status appears in the
status bar.

### HTML and images

NeoMutt renders HTML and image parts through external viewers configured in
`~/.config/neomutt/mailcap`:

- **HTML** is converted to plain text with `w3m -dump`.
- **Images** are rendered inline with `chafa`:
  - `--format sixel` for terminals that support SIXEL (your terminal `foot`
    does).
  - `--symbols block` as a plain-Unicode fallback.

`allow_ansi = yes` lets those viewers emit terminal escape sequences. In the
message index, press `v` to see the attachment list, select an image, and press
Enter to view it.

### Interface

A left sidebar lists the main Posteo folders (`INBOX`, `Sent`, `Drafts`,
`Trash`). Key bindings while reading or in the index:

- `Ctrl-p` / `Ctrl-n` — previous / next folder in the sidebar
- `Ctrl-o` — open the selected folder
- `B` — toggle the sidebar visibility

The default theme is a simple dark-terminal scheme; colors are set in the
module and can be edited there.

### Sending encrypted mail

In the compose screen press `p` to open the PGP menu and pick the operation
(sign, encrypt, sign+encrypt). Nothing is signed or encrypted automatically:
`crypt_auto_sign` and `crypt_auto_encrypt` are both `no` on purpose.

Keys of correspondents are looked up in your GnuPG keyring, so import them
first:

```sh
gpg --import their-key.asc     # or: gpg --locate-keys them@example.org
```

GPGME does not fetch keys by itself.

## Posteo special folders

`record`, `postponed` and `trash` are set to `Sent`, `Drafts` and `Trash`. Posteo
names its IMAP folders after the webmail language, so a German account exposes
`Gesendet`, `Entwürfe` and `Papierkorb` instead, and saving/trashing will fail
until the names are corrected in the module.

To list the real names, start neomutt and press `?` in the folder browser, or
use the himalaya config as a cross-check.

## Posteo inbound encryption

Posteo only accepts public keys whose user ID does **not** contain a real name.
The key must use an empty name or the email address itself as the Real name
(with an empty Comment). If you previously created a key with a name such as
`gcreusot (mail) <gcreusot@posteo.com>`, create a new one with Real name
`gcreusot@posteo.com`, then re-encrypt the password store:

```sh
# The fingerprint of the nameless key configured in this module:
pass init AA1D7C396291AE68384FB36B3CAE98FFEDCE1EF1
```

`pass init` re-encrypts every entry in the store to the new key, so
`pass show mail/posteo` will ask for the new passphrase from now on.

Sending the public key to `keys@posteo.de` only *publishes* it in the Posteo key
directory. Inbound encryption is a separate switch under Settings → Key
administration, and activating it means:

- newly arriving mail is encrypted to your key,
- webmail can no longer read it (PGP is only readable there through Mailvelope),
- neomutt can read it, as long as the private key survives.

Before activating, back up `~/.gnupg` (or the exported secret key plus the
revocation certificate in `openpgp-revocs.d`) somewhere off this machine. The
password store is encrypted to the same key, so losing it also loses the
mailbox password.

## Troubleshooting

- **`Could not save message` / `Mailbox does not exist`** — wrong folder name,
  see above.
- **SMTP login is rejected** — the username is repeated in the URL
  (`smtps://user@domain@host:port`) because neomutt splits the URL at its last
  `@`. Check that both `@` are present.
- **pinentry does not appear** — `gpg-agent` must inherit `WAYLAND_DISPLAY` /
  `DISPLAY`; it does through `systemctl --user`, so a cold agent started outside
  the session is the usual cause. Restarting the session fixes it.
- **`pass show` fails** — see `docs/himalaya-tui.md`, `pass insert` prompts
  twice and echoes nothing.
