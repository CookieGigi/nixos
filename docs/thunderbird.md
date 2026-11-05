# thunderbird

Graphical mail client for the Posteo account, used when HTML rendering or
inline images matter more than a terminal workflow.

- Upstream: <https://www.thunderbird.net>
- Package: `pkgs.thunderbird`
- Module: `modules/home/cookiegigi/programs/thunderbird.nix`
- Profile: `~/.thunderbird`

## Why thunderbird

`neomutt` is fast and keyboard-driven, but it delegates HTML to `w3m -dump`,
which intentionally strips images and shows only alt text like `[Image 1]`.

Thunderbird is the fallback for rich newsletters, verification emails with
inline images, and anything that needs to look like a web page.

## Shared secret material

Thunderbird uses its own OpenPGP engine (RNP), not `gpg`. The first time you
compose or read encrypted mail it will offer to import your GnuPG secret key
from `~/.gnupg`. After importing, the key is also stored inside the Thunderbird
profile, so the profile backup becomes important.

The mailbox password is still in `pass show mail/posteo`; you can paste it
during account setup or configure Thunderbird to look it up with an
OS-keyring integration later.

## Setup

1. Rebuild and launch Thunderbird:
   ```sh
   sudo nixos-rebuild switch --flake .#xps
   thunderbird
   ```

2. Add the Posteo account through the first-run wizard:
   - Name: `gcreusot@posteo.com` (or leave the display name empty)
   - Email: `gcreusot@posteo.com`
   - Password: `pass show mail/posteo`
   - Thunderbird should auto-detect Posteo IMAP/SMTP settings.

3. For OpenPGP:
   - Settings → End-To-End Encryption → OpenPGP Key Manager.
   - Import the existing GnuPG key from `~/.gnupg` (fingerprint
     `AA1D 7C39 6291 AE68 384F B36B 3CAE 98FF EDCE 1EF1`).

## Persistence

The profile is persisted under `home.persistence."/persist"` as `~/.thunderbird`.
Losing that directory loses the account config, downloaded messages, and the
imported OpenPGP secret key, so keep an offline backup after everything works.
