# OpenCode Configuration in NixOS

> This document captures everything relevant about how OpenCode stores its configuration and state, and how to manage it declaratively in this NixOS flake.

## Overview

[OpenCode](https://github.com/opencode-ai/opencode) (`pkgs.opencode`) is a terminal-based AI coding agent (Go + TUI). It is **not** natively Nix-aware: it expects a JSON config file and mutable state directories. Because this host uses **impermanence** (`/` is tmpfs), we must explicitly persist its stateful paths.

---

## Paths Used by OpenCode

| Path | Purpose | Persistence Required |
|------|---------|----------------------|
| `~/.config/opencode/.opencode.json` | **Main configuration file** (agents, providers, themes, LSP, MCP, shell, etc.) | Yes |
| `~/.config/opencode/package.json` | Plugin manifest (managed by `opencode plugin`) | Yes |
| `~/.local/share/opencode/` | Auth tokens (`auth.json`), SQLite DB, session snapshots, logs | Yes |
| `~/.local/state/opencode/` | Model preferences (`model.json`) | Yes |
| `~/.cache/opencode/` | Cache, downloaded binaries, logs | No (rebuildable) |

Current persistence is declared in `modules/programs/opencode.nix`:

```nix
environment.persistence."/persist" = {
  hideMounts = true;
  directories = [
    "/home/cookiegigi/.config/opencode"
    "/home/cookiegigi/.local/share/opencode"
    "/home/cookiegigi/.local/state/opencode"
  ];
};
```

---

## Configuration File: `.opencode.json`

OpenCode searches for config in this order:

1. `$HOME/.opencode.json`
2. `$XDG_CONFIG_HOME/opencode/.opencode.json`
3. `./.opencode.json` (project-local, in CWD)

The canonical location for user-wide config is **`~/.config/opencode/.opencode.json`**.

### Key Structure

```json
{
  "agents": {
    "coder":   { "model": "claude-3.7-sonnet", "maxTokens": 5000 },
    "task":    { "model": "claude-3.7-sonnet", "maxTokens": 5000 },
    "title":   { "model": "claude-3.7-sonnet", "maxTokens": 80 }
  },
  "shell": {
    "path": "/bin/bash",
    "args": ["-l"]
  },
  "autoCompact": true,
  "debug": false,
  "debugLSP": false,
  "tui": {
    "theme": "opencode"
  },
  "providers": {
    "anthropic": { "apiKey": "...", "disabled": false },
    "openai":    { "apiKey": "...", "disabled": false }
  },
  "lsp": {
    "go": { "command": "gopls", "disabled": false }
  },
  "mcpServers": {
    "example": {
      "type": "stdio",
      "command": "path/to/mcp-server",
      "args": [],
      "env": []
    }
  },
  "contextPaths": [
    ".github/copilot-instructions.md",
    ".cursorrules",
    "CLAUDE.md",
    "opencode.md"
  ]
}
```

See also the upstream schema: `opencode-schema.json` in the [opencode repo](https://github.com/opencode-ai/opencode).

---

## Managing Config with Nix

### Approach 1: Activation Script (Current, No home-manager)

Since this flake does **not** use home-manager, the simplest way is to generate the JSON with Nix and copy it into place with a `system.activationScript`. We **copy** rather than symlink because OpenCode may want to mutate the file later (symlinks to the read-only Nix store would cause `EROFS`).

Example `modules/programs/opencode.nix`:

```nix
{
  pkgs,
  lib,
  ...
}: let
  opencodeConfig = (pkgs.formats.json {}).generate "opencode.json" {
    agents = {
      coder = {
        model = "claude-3.7-sonnet";
        maxTokens = 5000;
      };
      task = {
        model = "claude-3.7-sonnet";
        maxTokens = 5000;
      };
      title = {
        model = "claude-3.7-sonnet";
        maxTokens = 80;
      };
    };

    shell = {
      path = "${pkgs.bash}/bin/bash";
      args = ["-l"];
    };

    autoCompact = true;

    tui.theme = "tokyonight";

    # Example: enable nil LSP for Nix files
    lsp = {
      nix = {
        command = "${pkgs.nil}/bin/nil";
      };
    };
  };
in {
  environment.systemPackages = [
    pkgs.opencode
  ];

  # Seed the config file only if it does not already exist.
  # Because ~/.config/opencode is persisted, this is usually a no-op
  # after the first boot.
  system.activationScripts.opencode-config = ''
    mkdir -p /home/cookiegigi/.config/opencode
    if [ ! -f /home/cookiegigi/.config/opencode/.opencode.json ]; then
      cp ${opencodeConfig} /home/cookiegigi/.config/opencode/.opencode.json
      chown cookiegigi:users /home/cookiegigi/.config/opencode/.opencode.json
      chmod 644 /home/cookiegigi/.config/opencode/.opencode.json
    fi
  '';

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/home/cookiegigi/.config/opencode"
      "/home/cookiegigi/.local/share/opencode"
      "/home/cookiegigi/.local/state/opencode"
    ];
  };
}
```

**Trade-off:** OpenCode may later rewrite `.opencode.json` (e.g. when changing models via the TUI). Because the file is persisted, those mutations survive reboots. If you want to force a reset to the Nix-defined version, delete the file and rebuild.

### Approach 2: home-manager

If home-manager is added as a flake input (see `docs/TODO.md`), dotfiles can be managed like this:

```nix
xdg.configFile."opencode/.opencode.json".source =
  (pkgs.formats.json {}).generate "opencode.json" { /* ... */ };
```

**Caveat:** `xdg.configFile` creates a symlink by default. If OpenCode tries to overwrite the file in-place, it will fail. Use a `home.activation` script that copies instead, or check whether OpenCode unlinks before writing.

---

## Secrets: Do NOT Put API Keys in the Nix Store

The Nix store is world-readable. Never write raw API keys into `.opencode.json` inside a Nix expression.

OpenCode supports environment variables for every major provider:

| Variable | Provider |
|----------|----------|
| `ANTHROPIC_API_KEY` | Anthropic Claude |
| `OPENAI_API_KEY` | OpenAI |
| `GITHUB_TOKEN` | GitHub Copilot |
| `GEMINI_API_KEY` | Google Gemini |
| `GROQ_API_KEY` | Groq |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_REGION` | AWS Bedrock |
| `AZURE_OPENAI_ENDPOINT` / `AZURE_OPENAI_API_KEY` | Azure OpenAI |
| `LOCAL_ENDPOINT` | Self-hosted (OpenAI-like) |

Set these via `environment.sessionVariables` (global) or `systemd.user.sessionVariables` (user services / graphical session). For stronger secret management, adopt `sops-nix` or `agenix` (also tracked in `docs/TODO.md`).

---

## Custom Commands

OpenCode supports custom user commands stored as Markdown files:

- **User commands**: `~/.config/opencode/commands/*.md`
- **Project commands**: `<project>/.opencode/commands/*.md`

Because `~/.config/opencode` is already persisted, custom commands survive reboots automatically.

---

## LSP & MCP

- **LSP** servers are declared under the `lsp` key in `.opencode.json`.
- **MCP** servers are declared under `mcpServers`.

Both can reference Nix store paths via interpolation in the Nix expression, ensuring the required binaries (e.g. `gopls`, `typescript-language-server`) are available without relying on a manual `$PATH`.

---

## OpenCode TUI Themes

Available themes (from the schema):

- `opencode` (default)
- `catppuccin`
- `dracula`
- `flexoki`
- `gruvbox`
- `monokai`
- `onedark`
- `tokyonight`
- `tron`

---

## Useful Commands

```bash
# Show resolved config
opencode debug config

# Show all data / state / cache paths
opencode debug paths

# Show agent configuration
opencode debug agent <name>

# List available agents
opencode agent list

# Manage providers
opencode providers

# List available models
opencode models [provider]
```

---

## Project Status

> ⚠️ The upstream [opencode-ai/opencode](https://github.com/opencode-ai/opencode) repository was **archived on 2025-09-18** and is now read-only. Development continues under the name **[Crush](https://github.com/charmbracelet/crush)** by the original author and the Charm team.

This means:
- `pkgs.opencode` in nixpkgs may eventually stop receiving updates.
- If migrating to Crush in the future, evaluate whether its config paths and schema have changed.

---

## References

- Upstream repo (archived): https://github.com/opencode-ai/opencode
- Successor project: https://github.com/charmbracelet/crush
- Current module: `modules/programs/opencode.nix`
- Persistence module: `modules/core.nix` (defines `environment.persistence`)
