{lib, ...}: {
  # ── Leader key ──────────────────────────────────────────────
  globals.mapleader = " ";
  globals.maplocalleader = " ";

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

  # ── Diagnostics ───────────────────────────────────────────────
  diagnostic.settings = {
    virtual_text = true;
    signs = true;
    underline = true;
    update_in_insert = false;
    severity_sort = true;
    float = {
      border = "rounded";
      source = "if_many";
    };
  };

  # ── Plugins ─────────────────────────────────────────────────
  plugins = {
    # Which-key (show available keymaps after leader)
    which-key.enable = true;

    # LSP
    lsp = {
      enable = true;
      servers = {
        nil_ls.enable = true;
      };
      keymaps = {
        silent = true;
        diagnostic = {
          "<leader>d" = {
            action = "open_float";
            desc = "Open diagnostic float";
          };
          "[d" = {
            action = "goto_prev";
            desc = "Previous diagnostic";
          };
          "]d" = {
            action = "goto_next";
            desc = "Next diagnostic";
          };
        };
        lspBuf = {
          "gd" = {
            action = "definition";
            desc = "Go to definition";
          };
          "gr" = {
            action = "references";
            desc = "Go to references";
          };
          "gI" = {
            action = "implementation";
            desc = "Go to implementation";
          };
          "K" = {
            action = "hover";
            desc = "Hover documentation";
          };
          "<leader>rn" = {
            action = "rename";
            desc = "Rename symbol";
          };
          "<leader>ca" = {
            action = "code_action";
            desc = "Code action";
          };
        };
      };
    };

    # Conform (formatting)
    conform-nvim = {
      enable = true;
      autoInstall.enable = false;
      settings = {
        format_on_save = {
          lsp_format = "fallback";
          timeout_ms = 500;
        };
        formatters_by_ft = {
          nix = ["alejandra"];
        };
      };
    };

    # Lint (linters)
    lint = {
      enable = true;
      autoInstall.enable = false;
      lintersByFt = {
        nix = [
          "statix"
          "deadnix"
        ];
      };
      linters = {
        statix = {
          cmd = "statix";
          args = [
            "check"
            "-i"
            "--stdin"
          ];
          stdin = true;
        };
        deadnix = {
          cmd = "deadnix";
          args = ["-"];
          stdin = true;
        };
      };
      autoCmd = {
        event = [
          "BufWritePost"
          "InsertLeave"
        ];
        callback = lib.nixvim.mkRaw ''
          function()
            require('lint').try_lint()
          end
        '';
      };
    };

    # Autocompletion (blink-cmp)
    blink-cmp = {
      enable = true;
      setupLspCapabilities = true;
      settings = {
        keymap.preset = "default";
        completion = {
          accept.auto_brackets.enabled = true;
          documentation.auto_show = true;
          ghost_text.enabled = true;
        };
        signature.enabled = true;
        appearance = {
          use_nvim_cmp_as_default = true;
          nerd_font_variant = "normal";
        };
      };
    };

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
    # Format
    {
      key = "<leader>f";
      action = "<cmd>lua require('conform').format({ async = true, lsp_format = 'fallback' })<cr>";
      mode = [
        "n"
        "v"
      ];
      options = {
        desc = "Format buffer";
      };
    }
  ];
}
