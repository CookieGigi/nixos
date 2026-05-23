_: {
  programs.git = {
    enable = true;

    ignores = [".direnv/" "*.swp" ".DS_Store"];

    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      extraConfig.core.editor = "vi";
      user.name = "cookiegigi";
      user.email = "cookiegigi@cookiegigi.com";
      gpg.format = "ssh";

      aliases = {
        unstage = "reset HEAD --";
      };
    };

    signing = {
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
    };
  };
}
