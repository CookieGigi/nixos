# NixOS Config TODO

## Security
- [x] Remove hardcoded `users.users.cookiegigi.initialPassword` — password set manually with `passwd`; /etc/shadow + /etc/passwd persisted via impermanence so it survives reboots
- [ ] Evaluate LUKS keyfile / TPM2 / Yubikey unlock via `systemd-cryptenroll`

- [ ] git-hooks in nix

## Style
- [ ] firefox style
- 
