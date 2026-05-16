# Home Manager in This Flake

Quick reference for using and extending Home Manager in this NixOS configuration.

## How It Is Wired

- **Flake input**: `home-manager` is declared in `flake.nix` and passed to `nixosConfigurations.xps`.
- **NixOS module**: `home-manager.nixosModules.home-manager` is imported in the system configuration.
- **Global settings**: `modules/home/default.nix` sets:
  - `home-manager.useGlobalPkgs = true` — uses the system `pkgs` instead of a private instance.
  - `home-manager.useUserPackages = true` — installs user packages into `/etc/profiles` instead of `~/.nix-profile`.
- **User entrypoint**: `modules/home/cookiegigi/default.nix` defines `home-manager.users.cookiegigi`.
  - `home.stateVersion = "25.11"`; do not change this.

## Adding Home-Manager Config

Inside `modules/home/cookiegigi/`, create or edit `.nix` files and import them in `default.nix`:

```nix
home-manager.users.cookiegigi = {
  imports = [
    ./packages.nix
    ./programs
    # add new modules here
  ];

  home.stateVersion = "25.11";
};
```

### Packages

Use `home.packages` to install software into the user profile:

```nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    htop
    ripgrep
  ];
}
```

### Program Configurations

Enable and configure supported programs under `programs.<name>`:

```nix
{...}: {
  programs.git = {
    enable = true;
    userName = "cookiegigi";
    userEmail = "cookiegigi@example.org";
  };
}
```

Common program modules include `git`, `vim`, `bash`, `zsh`, `firefox`, `direnv`, `starship`, etc.

### Services

Enable user services under `services.<name>`:

```nix
{...}: {
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };
}
```

### Dotfiles / Arbitrary Files

Use `home.file` or `xdg.configFile` to link files into `$HOME`:

```nix
{...}: {
  home.file.".config/myapp/config.toml".source = ./config.toml;
  xdg.configFile."myapp/config.toml".source = ./config.toml;
}
```

- `xdg.configFile` maps to `~/.config/` (or `$XDG_CONFIG_HOME`).
- `xdg.dataFile` maps to `~/.local/share/`.
- To link a directory recursively, add `recursive = true;`.
- To force overwrite an existing file, add `force = true;` (use carefully).
- To create a symlink to a mutable path outside the Nix store, use `config.lib.file.mkOutOfStoreSymlink ./path`.

## Important Notes

- **Impermanence**: Because `/` is tmpfs on this host, files placed directly in `$HOME` by Home Manager will survive reboots only if the parent directory is declared in the impermanence config. The current setup already handles typical paths via `modules/home/cookiegigi/persistence.nix` and system-level `environment.persistence."/persist"`.
- **State version**: `home.stateVersion` should stay at the value you originally installed. It gates breaking changes. Do not bump it without reading the Home Manager release notes.
- **Activation**: When used as a NixOS module, `home-manager` activation happens automatically during `nixos-rebuild switch`. No separate `home-manager switch` is needed.
- **Troubleshooting**: If a rebuild does not produce the expected environment, check the activation log:
  ```
  systemctl status home-manager-cookiegigi.service
  ```

## Rollbacks

Home Manager keeps generations. To roll back to the previous generation:

```bash
home-manager switch --rollback
```

Or use `nixos-rebuild switch --rollback` for the whole system.

## Finding Options

- **Terminal**: `man home-configuration.nix`
- **Web**: https://nix-community.github.io/home-manager/options.xhtml
- **NixOS module options**: https://nix-community.github.io/home-manager/nixos-options.xhtml

## Reference Links

- Home Manager Manual: https://nix-community.github.io/home-manager/
- Home Manager Options: https://nix-community.github.io/home-manager/options.xhtml
- Source / Issues: https://github.com/nix-community/home-manager
