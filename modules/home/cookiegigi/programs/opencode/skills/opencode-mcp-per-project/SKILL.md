---
name: opencode-mcp-per-project
description: This skill should be used when configuring Model Context Protocol (MCP) servers in OpenCode on a per-project basis. It covers creating project-local .opencode.json files, selecting appropriate MCP servers for different project types (web, backend, infrastructure, data), and managing local vs remote MCP server configurations.
---

# OpenCode MCP Per-Project Configuration

## Overview

OpenCode supports project-level configuration via a `.opencode.json` file in the project root. When present, this file merges with the global `~/.config/opencode/opencode.json`, allowing project-specific MCP servers, agents, and tool settings without polluting the global configuration.

This skill enables declarative, per-project MCP server configuration for OpenCode users on NixOS (or any system) who want to keep project-specific tool integrations scoped to individual repositories.

## When to Use This Skill

Use this skill when:
- A project needs MCP servers that do not apply globally (e.g., a Postgres MCP server only for a backend project)
- Different projects require different versions or configurations of the same MCP server
- The global OpenCode config is managed declaratively (e.g., via Nix/home-manager) and should not be mutated for temporary project needs
- Setting up a new project and wanting to include OpenCode-specific tooling as part of the project scaffold

## Config Precedence

OpenCode loads configuration in this order (later overrides earlier):

1. Global config: `~/.config/opencode/opencode.json`
2. Project config: `./.opencode.json` (in current working directory)

Project-local values override global values for the same keys. The `mcp` object is merged at the server-name level.

## Workflow

### Step 1: Identify Project MCP Needs

Determine which MCP servers are relevant to the project:

| Project Type | Common MCP Servers |
|--------------|-------------------|
| Web frontend | `github` (search code), `context7` (docs), `playwright` (browser testing) |
| Backend/API | `postgres` (database), `sqlite` (local DB), `github` (issues/PRs) |
| Infrastructure | `nix` (nixpkgs search), `docker` (container management) |
| Data/ML | `pandas` (data analysis), `jupyter` (notebooks) |
| General | `context7` (documentation), `duckduckgo` (web search) |

### Step 2: Select Server Type

Choose between local and remote MCP servers:

- **Local**: Runs as a subprocess on the machine. Requires the binary to be available (e.g., via `npx`, `bun x`, or Nix package).
- **Remote**: Connects to an HTTP/SSE endpoint. Useful for SaaS integrations (Sentry, Context7, etc.).

### Step 3: Create Project Config File

Create a `.opencode.json` in the project root directory. Start from the template in `assets/project-opencode.json` or build it manually.

Minimum structure for MCP-only project config:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "server-name": {
      "type": "local",
      "command": ["npx", "-y", "mcp-server-package"],
      "enabled": true
    }
  }
}
```

### Step 4: Ensure Binary Availability

For local MCP servers, the command binary must be resolvable:

- **NixOS**: Add the package to the project's `flake.nix` devShell or to the system configuration
- **Non-Nix**: Ensure `node`, `bun`, or the required runtime is in `$PATH`
- **npx/bun x**: These resolve packages from the npm registry on first run

### Step 5: Test and Verify

After creating `.opencode.json`:

1. Run `opencode mcp list` to verify the server appears
2. Run `opencode mcp debug <server-name>` if the server fails to connect
3. Prompt OpenCode with `use <server-name>` to test tool invocation

## Important Considerations

### Context Budget

MCP servers add tool descriptions to the LLM context. Each enabled server consumes tokens. For projects with many MCP servers:

- Disable unused servers (`"enabled": false`)
- Use per-agent tool enablement (disable globally, enable in specific agents)
- Prefer remote servers with focused toolsets over local "everything" servers

### Secrets and Environment Variables

Never commit API keys in `.opencode.json`. Use environment variable interpolation:

```json
{
  "mcp": {
    "github": {
      "type": "remote",
      "url": "https://api.github.com/mcp",
      "headers": {
        "Authorization": "Bearer {env:GITHUB_TOKEN}"
      }
    }
  }
}
```

For NixOS users, set environment variables via:
- `environment.sessionVariables` in system config
- `home.sessionVariables` in home-manager
- Project-local `.envrc` with direnv (ensure `.envrc` is in `.gitignore`)

### NixOS Specifics

On this NixOS host:
- Global OpenCode config is managed at `modules/home/cookiegigi/programs/opencode/` and rebuilt with `nixos-rebuild switch`
- Project-local `.opencode.json` is mutable and not managed by Nix
- If a project needs a local MCP binary, add the package to the appropriate Nix module or project flake
- The `~/.config/opencode` directory is generated on activation; do not edit it manually

## Resources

### references/mcp-configuration.md
Detailed reference covering:
- Full MCP server configuration options (all fields, types, defaults)
- Common MCP server recipes (Postgres, SQLite, GitHub, Sentry, Context7, filesystem)
- OAuth authentication flows
- Troubleshooting connection issues
- Glob patterns for tool enablement/disablement

### assets/project-opencode.json
A starter template for `.opencode.json` with commented examples for local and remote MCP servers.

Load this template when scaffolding a new project that needs MCP configuration.
