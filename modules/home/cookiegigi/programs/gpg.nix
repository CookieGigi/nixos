{pkgs, ...}: {
  # Password strategy: pass (password-store), backed by GnuPG.
  # Shared by every mail client (neomutt, himalaya-tui): the store holds the
  # mailbox passwords and the GPG key decrypts them.
  programs.password-store.enable = true;

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    # GUI pinentry: the mail clients own the terminal, so pinentry-curses
    # would fight them for it. pinentry-qt talks Wayland natively.
    pinentry.package = pkgs.pinentry-qt;
    defaultCacheTtl = 3600;
    maxCacheTtl = 7200;
  };

  # ── Persistence ────────────────────────────────────────────────
  home.persistence."/persist" = {
    directories = [
      # Encrypted password store.
      {
        directory = ".password-store";
        mode = "0700";
      }
      # GPG key + trustdb protecting the store. GnuPG rejects a group/world
      # readable homedir, so it must not use impermanence's 0755 default.
      {
        directory = ".gnupg";
        mode = "0700";
      }
    ];
  };
}
