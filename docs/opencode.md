# OpenCode Configuration in NixOS

> This document captures everything relevant about how OpenCode stores its configuration and state, and how to manage it declaratively in this NixOS flake.

## Overview

[OpenCode](https://github.com/opencode-ai/opencode) (`pkgs.opencode`) is a terminal-based AI coding agent (Go + TUI). It is **not** natively Nix-aware: it expects a JSON config file and mutable state directories. Because this host uses **impermanence** (`/` is tmpfs), we must explicitly persist its stateful paths.

---

## Paths Used by OpenCode

| Path | Purpose | Persistence Required |
|------|---------|----------------------|
| `~/.config/opencode/opencode.json` | **Main configuration file** (agents, providers, themes, LSP, MCP, shell, etc.) | Yes |
| `~/.config/opencode/package.json` | Plugin manifest (managed by `opencode plugin`) | Yes |
| `~/.local/share/opencode/` | Auth tokens (`auth.json`), SQLite DB, session snapshots, logs | Yes |
| `~/.local/state/opencode/` | Model preferences (`model.json`) | Yes |
| `~/.cache/opencode/` | Cache, downloaded binaries, logs | No (rebuildable) |

Current persistence is declared in `modules/home/cookiegigi/programs/opencode/default.nix`:

```nix
home.persistence."/persist" = {
  directories = [
    ".local/share/opencode"
    ".local/state/opencode"
  ];
};
```

---

## Configuration File: `opencode.json`

OpenCode searches for config in this order:

1. `$HOME/.opencode.json`
2. `$XDG_CONFIG_HOME/opencode/opencode.json`
3. `./.opencode.json` (project-local, in CWD)

The canonical location for user-wide config is **`~/.config/opencode/opencode.json`**.

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

This flake uses **home-manager** to manage OpenCode configuration. The module lives at `modules/home/cookiegigi/programs/opencode/`.

### Structure

The module is split into focused files to keep each file small and single-purpose:

```
modules/home/cookiegigi/programs/opencode/
├── default.nix        # Entry point: assembles config, wires xdg.configFile
├── lib.nix            # Shared helpers (e.g. `mkSkill`)
├── config.nix         # Top-level JSON config (model, tools, LSP, MCP, etc.)
├── agents.md.nix      # AGENTS.md content
├── tui.nix            # TUI theme JSON
├── agents/
│   ├── default.nix    # Merges all agent files
│   ├── explaining.nix # Explaining agent
│   ├── configuration.nix # Configuration agent
│   └── git-commit.nix # Git commit agent
└── skills/
    ├── default.nix    # Imports all skill files
    ├── impermanence.nix
    ├── nix-basics.nix
    └── nixos-rebuild.nix
```

### Adding a new agent

1. Create `agents/<name>.nix` returning `{ <name> = { ... }; }`
2. Add one line to `agents/default.nix`

### Adding a new skill

1. Create `skills/<name>.nix` using `mkSkill` from `lib.nix`
2. Add one line to `skills/default.nix`

### home-manager wiring

`default.nix` uses `xdg.configFile` (the canonical home-manager abstraction for `$XDG_CONFIG_HOME`):

```nix
xdg.configFile = {
  "opencode/opencode.json".source = opencodeJson;
  "opencode/AGENTS.md".source = agentsMd;
  "opencode/tui.json".source = tuiJson;
} // skillFiles;
```

**Caveat:** `xdg.configFile` creates a symlink to the Nix store by default. If OpenCode tries to overwrite `opencode.json` in-place (e.g. when changing models via the TUI), it may fail because the Nix store is read-only. Many applications `unlink()` before writing, which "just works" (the symlink breaks and a regular mutable file is created). If OpenCode does not do this, add a `home.activation` script that copies the file instead.

---

## Secrets: Do NOT Put API Keys in the Nix Store

The Nix store is world-readable. Never write raw API keys into `opencode.json` inside a Nix expression.

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

- **LSP** servers are declared under the `lsp` key in `opencode.json`.
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
- Current module: `modules/home/cookiegigi/programs/opencode/`
- Persistence module: `modules/core.nix` (defines `environment.persistence`)
