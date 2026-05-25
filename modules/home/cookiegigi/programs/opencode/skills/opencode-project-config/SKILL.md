---
name: opencode-project-config
description: This skill should be used when setting up or configuring per-project formatter and LSP settings for OpenCode. It auto-detects the project's language/tooling, generates a project-local .opencode.json with explicit formatter and LSP configurations, and optionally scaffolds a local flake.nix devShell with the required Nix packages.
---

# OpenCode Project-Level Formatter and LSP Configuration

## Overview

OpenCode supports project-level configuration via a `.opencode.json` file in the project root. When present, this file merges with the global `~/.config/opencode/opencode.json`, allowing project-specific formatter and LSP settings without polluting the global configuration.

OpenCode built-in formatters and LSP servers are powerful but can be ambiguous when enabled globally with `formatter: true` or `lsp: true`. Different projects may need different tools, and the global config may not have the right packages installed. This skill enables declarative, per-project, language-specific formatter and LSP configuration.

This skill is particularly useful for NixOS users who manage their global OpenCode config declaratively and want to keep project-specific tool dependencies scoped to individual project flakes.

## When to Use This Skill

Use this skill when:
- Starting a new project and wanting to configure OpenCode formatters and LSP for the project's language
- An existing project needs formatter/LSP settings that differ from the global config
- The global OpenCode config lacks the necessary formatter or LSP binary (e.g., `rustfmt`, `rust-analyzer`)
- A `.opencode.json` file needs to be created or updated for a project
- The user asks about per-project formatter or LSP setup

## Important Distinction: Global vs Local Skills

On this NixOS host, there are two places where skills can exist:

1. **Global skills** (managed by NixOS, apply to all projects):
   - Located at `modules/home/cookiegigi/programs/opencode/skills/`
   - Registered in `default.nix`
   - Deployed to `~/.config/opencode/skills/` on rebuild
   - Changes require `nixos-rebuild switch`

2. **Project-local skills** (ephemeral, project-specific):
   - Located in the project directory itself (e.g., `./.opencode/skills/my-skill/`)
   - Not tracked by NixOS
   - Must be added to the project's `.opencode.json` `skills` configuration manually
   - Useful for project-specific workflows without polluting global config

**This skill is a GLOBAL skill.** It was created in the NixOS-managed skills directory and is available system-wide. If a skill is specific to a single project and should not be global, place it in the project directory and configure `skills.paths` in that project's `.opencode.json`.

## Workflow

### Step 1: Run the Configuration Generator

Navigate to the project root directory and run:

```bash
python3 /home/cookiegigi/.config/opencode/skills/opencode-project-config/scripts/generate-config.py
```

The script will:
1. Scan the project directory for language indicator files and extensions
2. Detect the project type(s)
3. Generate a `.opencode.json` with explicit `formatter` and `lsp` configurations
4. Generate or suggest a `flake.nix` devShell with the required Nix packages

### Step 2: Review Generated Files

After running the script, review the generated files:

- **`.opencode.json`** — Contains explicit formatter and LSP entries for detected languages. Only the tools relevant to the project are configured.
- **`flake.nix`** (if generated) — Contains a `devShells.default` with the required packages. Enter the shell with `nix develop` to make the tools available in `$PATH`.

### Step 3: Enter the Development Shell

If a `flake.nix` was generated or modified:

```bash
nix develop
```

This makes the formatter and LSP binaries available to OpenCode.

### Step 4: Verify OpenCode Configuration

After entering the dev shell, verify that OpenCode recognizes the new configuration:

```bash
# Check if LSP is active
opencode lsp list

# Try formatting a file
opencode fmt <file>
```

## Detection Matrix

The script detects projects based on files and extensions. See `references/project-types.md` for the complete detection matrix, including:
- Detection indicators (files, extensions)
- Formatter configuration entries
- LSP configuration entries
- Required Nix packages

## Resources

### references/project-types.md
Detailed reference covering the full detection matrix for all supported languages, including exact formatter and LSP config objects and the corresponding Nix packages.

### scripts/generate-config.py
The main script that auto-detects the project type and generates `.opencode.json` and `flake.nix` files.

Load this script when the user wants to set up per-project formatter and LSP configuration.
