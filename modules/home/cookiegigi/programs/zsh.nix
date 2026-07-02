{lib, ...}: {
  programs.zsh = {
    enable = true;

    # ── Behaviour ────────────────────────────────────────────────
    autocd = true;

    # ── History ──────────────────────────────────────────────────
    history = {
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
    };

    # ── History substring search ─────────────────────────────────
    historySubstringSearch = {
      enable = true;
    };

    # ── Aliases ──────────────────────────────────────────────────
    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      grep = "grep --color=auto";
      ip = "ip -color=auto";
      diff = "diff --color=auto";
      mkdir = "mkdir -p";
    };

    # ── Oh-My-Zsh ────────────────────────────────────────────────
    oh-my-zsh = {
      enable = true;
      theme = "gnzh";
      plugins = [
        "git"
        "sudo"
        "colored-man-pages"
        "extract"
      ];
    };

    # ── Autosuggestions ──────────────────────────────────────────
    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };

    # ── Syntax highlighting ──────────────────────────────────────
    syntaxHighlighting = {
      enable = true;
    };

    # ── .zshrc content (ordered init) ────────────────────────────
    initContent = lib.mkMerge [
      # Order 550: before compinit (autocorrection)
      (lib.mkOrder 550 ''
        # Autocorrect minor typos (e.g. "sl" → "ls")
        ENABLE_CORRECTION="true"
      '')

      # Order 1000: general config (completion, prompt, bindkeys)
      ''
        # ── Environment variables ───────────────────────────────
        # Force proton-pass-cli to use D-Bus Secret Service instead of
        # the kernel keyring, which fails with EACCES on Linux 7.x.
        export PROTON_PASS_LINUX_KEYRING="dbus"

        # ── Completion ──────────────────────────────────────────
        # Case-insensitive completion
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'm:{A-Z}={a-z}'

        # Menu-based selection on second <Tab>
        zstyle ':completion:*' menu select
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
        zstyle ':completion:*:warnings' format '%F{red}no matches%f'

        # ── Virtual-env prompt indicator ────────────────────────
        if [[ -n $IN_NIX_SHELL || -n $DIRENV_DIR ]]; then
          export VIRTUAL_ENV_DISABLE_PROMPT=1
        fi

        # ── Key bindings ────────────────────────────────────────
        bindkey '^[[1;5D' backward-word
        bindkey '^[[1;5C' forward-word
        bindkey '^[[H' beginning-of-line
        bindkey '^[[F' end-of-line
        bindkey '^[[3~' delete-char
      ''

      # ── Foot shell integration ───────────────────────────────────
      (lib.mkOrder 1200 ''
        # OSC-7: report current working directory to foot
        function osc7-pwd() {
          emulate -L zsh
          setopt extendedglob
          local LC_ALL=C
          printf '\e]7;file://%s%s\e\\' $HOST ''${PWD//(#m)([^@-Za-z&-;_~])/%''${(l:2::0:)$(([##16]#MATCH))}}
        }
        function chpwd-osc7-pwd() {
          (( ZSH_SUBSHELL )) || osc7-pwd
        }
        add-zsh-hook -Uz chpwd chpwd-osc7-pwd

        # OSC-133: prompt markers for jumping between prompts (Ctrl+Shift+z/x)
        function precmd() {
          print -Pn "\e]133;A\e\\"
        }
        function preexec() {
          print -n "\e]133;C\e\\"
        }
      '')
    ];
  };

  # ── Persistence ────────────────────────────────────────────────
  home.persistence."/persist" = {
    directories = [
      ".zsh"
    ];

    files = [
      ".zsh_history"
    ];
  };
}
