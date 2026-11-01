{
  pkgs,
  inputs,
  ...
}: {
  # himalaya-tui has no nixpkgs package yet and no tagged releases, so it is
  # built from the upstream flake (Rust, fenix toolchain).
  home.packages = [
    inputs.himalaya-tui.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Password strategy: pass (password-store), backed by GnuPG.
  # Secrets live in ~/.password-store and are read by himalaya through
  # `password.command = "pass show <entry>"` (set by the TUI wizard or in
  # ~/.config/himalaya/config.toml).
  programs.password-store.enable = true;

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    # GUI pinentry: himalaya-tui owns the terminal, so pinentry-curses would
    # fight the TUI for it. pinentry-qt talks Wayland natively.
    pinentry.package = pkgs.pinentry-qt;
    defaultCacheTtl = 3600;
    maxCacheTtl = 7200;
  };

  # ── Persistence ────────────────────────────────────────────────
  home.persistence."/persist" = {
    directories = [
      # Wizard-written account config (includes the password command).
      ".config/himalaya"
      # Encrypted password store.
      ".password-store"
      # GPG key + trustdb protecting the store.
      ".gnupg"
    ];
  };
}
