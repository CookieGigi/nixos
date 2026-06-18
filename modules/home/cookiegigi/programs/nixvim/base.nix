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

  # ── Custom commands ─────────────────────────────────────────
  extraConfigLua = ''
    vim.api.nvim_create_user_command("LspInfo", function()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      if #clients == 0 then
        vim.notify("No LSP clients attached to this buffer", vim.log.levels.INFO)
        return
      end

      local lines = { "Attached LSP clients:", "" }
      for _, client in ipairs(clients) do
        table.insert(lines, "• " .. client.name)
        table.insert(lines, "  id: " .. client.id)
        table.insert(lines, "  root_dir: " .. (client.config.root_dir or "N/A"))
        table.insert(lines, "  filetypes: " .. vim.inspect(client.config.filetypes or {}))
        table.insert(lines, "")
      end

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].modifiable = false
      vim.bo[buf].buftype = "nofile"

      local width = math.min(80, vim.o.columns - 4)
      local height = math.min(#lines + 2, vim.o.lines - 4)
      local col = math.floor((vim.o.columns - width) / 2)
      local row = math.floor((vim.o.lines - height) / 2)

      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
        title = " LspInfo ",
        title_pos = "center",
      })

      vim.keymap.set("n", "q", function()
        vim.api.nvim_win_close(win, true)
      end, { buffer = buf, silent = true })
      vim.keymap.set("n", "<Esc>", function()
        vim.api.nvim_win_close(win, true)
      end, { buffer = buf, silent = true })
    end, { desc = "Show attached LSP clients" })
  '';

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
        sources = {
          default = ["lsp" "path" "snippets" "buffer"];
          providers = {
            buffer = {
              score_offset = -7;
            };
            lsp = {
              fallbacks = [];
            };
          };
        };
      };
    };

    # Treesitter
    treesitter = {
      enable = true;
      settings.highlight.enable = true;
    };

    # Snacks (picker + lazygit)
    snacks = {
      enable = true;
      settings = {
        picker = {
          enabled = true;
        };
        lazygit = {
          enabled = true;
        };
      };
    };

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
    # Snacks pickers
    {
      key = "<leader>ff";
      action = "<cmd>lua Snacks.picker.files()<cr>";
      mode = "n";
      options = {
        desc = "Find files";
      };
    }
    {
      key = "<leader>fg";
      action = "<cmd>lua Snacks.picker.grep()<cr>";
      mode = "n";
      options = {
        desc = "Live grep";
      };
    }
    {
      key = "<leader>gg";
      action = "<cmd>lua Snacks.lazygit()<cr>";
      mode = "n";
      options = {
        desc = "Lazygit";
      };
    }
  ];
}
