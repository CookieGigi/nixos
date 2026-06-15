{pkgs, ...}: {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;

    # ── Line numbers ──────────────────────────────────────────────
    opts = {
      number = true;
      relativenumber = true;
    };

    # ── Colorscheme ─────────────────────────────────────────────
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "macchiato";
        transparent_background = true;
      };
    };

    # ── Plugins ─────────────────────────────────────────────────
    plugins = {
      # LSP
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true;
          qmlls = {
            enable = true;
            package = pkgs.kdePackages.qttools;
          };
        };
      };
      lsp-format.enable = true;

      # Treesitter
      treesitter = {
        enable = true;
        settings.highlight.enable = true;
      };

      # Snacks (picker + lazygit)
      snacks.enable = true;

      # Yazi file manager integration
      yazi.enable = true;

      # Hardtime (block arrow / repeat hjkl abuse)
      hardtime = {
        enable = true;
        settings = {
          timeout = 2000;
          max_count = 2;
          allow_different_key = true;
          show_message = true;
          disable_mouse = true;
        };
      };

      # Nix support
      nix.enable = true;
    };

    # ── Disable arrow keys (learn hjkl) ─────────────────────────
    keymaps = [
      # Normal mode
      {
        key = "<Up>";
        action = "<Nop>";
        mode = "n";
      }
      {
        key = "<Down>";
        action = "<Nop>";
        mode = "n";
      }
      {
        key = "<Left>";
        action = "<Nop>";
        mode = "n";
      }
      {
        key = "<Right>";
        action = "<Nop>";
        mode = "n";
      }
      # Insert mode
      {
        key = "<Up>";
        action = "<Nop>";
        mode = "i";
      }
      {
        key = "<Down>";
        action = "<Nop>";
        mode = "i";
      }
      {
        key = "<Left>";
        action = "<Nop>";
        mode = "i";
      }
      {
        key = "<Right>";
        action = "<Nop>";
        mode = "i";
      }
    ];
  };
}
