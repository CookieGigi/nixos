# NixOS Config TODO

## Security
- [ ] Replace hardcoded `users.users.cookiegigi.initialPassword` with `hashedPasswordFile` + secret management (sops-nix / agenix) or set manually at install time
- [ ] Evaluate LUKS keyfile / TPM2 / Yubikey unlock via `systemd-cryptenroll`
- [ ] Add secret management solution (sops-nix or agenix) for credentials, API keys, and hashed passwords

## Correctness
- [ ] Fix `xps-iso` config: it does not import `modules/core.nix`, desktop, user, programs, audio, or locale modules. Update `flake.nix` or `modules/iso.nix` to pull in the real host config, or update `AGENTS.md` to clarify intent
- [ ] Fix `system.stateVersion`: currently set to `"25.11"` which does not exist yet. Change to the actual install version (e.g. `"25.05"`)

## Maintainability
- [ ] Consolidate trivial `environment.systemPackages` modules (`wget.nix`, `xclip.nix`, `opencode.nix`) into a single `packages.nix` or `system-packages.nix`
- [ ] Rename `hosts/xps/disko.nix` to `disko-config.nix` or `devices.nix` to disambiguate from the Disko module import
- [ ] Add comment explaining the empty `@snapshots` subvolume, or remove it if unused

## Reliability / Performance
- [ ] Add automatic nix GC: `nix.gc.automatic = true` and `nix.gc.options = "--delete-older-than 30d"`
- [ ] Add `nix.settings.auto-optimise-store = true`
- [ ] Add `boot.loader.systemd-boot.configurationLimit = 10` (or similar) to prevent `/boot` ESP from filling up
- [ ] Re-evaluate `mode=755` on root tmpfs for user-writable edge cases

## Completeness
- [ ] Remove `hardware-configuration.nix` import from `xps-iso` (or define generic ISO hardware config) — host-specific Intel microcode is unnecessary in a live CD
- [ ] Explicitly set `nixpkgs.config.allowUnfree = true` (or keep `false` intentionally and document why)
- [ ] Consider adopting `home-manager` as a flake input to declaratively manage dotfiles instead of hand-maintaining `environment.persistence` entries for every new dotfile directory
