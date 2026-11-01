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

  # pass + GnuPG + gpg-agent live in ./gpg.nix, shared with neomutt.
  # himalaya reads its password through `passwd.command = ["pass", "show",
  # "mail/<account>"]` in ~/.config/himalaya/config.toml (written by the
  # first-run wizard).

  # ── Persistence ────────────────────────────────────────────────
  home.persistence."/persist" = {
    directories = [
      # Wizard-written account config (includes the password command).
      ".config/himalaya"
    ];
  };
}
