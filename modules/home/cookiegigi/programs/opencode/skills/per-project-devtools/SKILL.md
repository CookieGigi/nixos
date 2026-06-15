---
name: per-project-devtools
description: This skill should be used when a project needs language-specific tooling configured (LSP, formatter, linter). Triggered when a project lacks .opencode.json, when a user asks to set up tooling for a specific language, or when working on a new project that needs development environment configuration.
---

# Per-Project Development Tools

## Overview

Configure language-specific tooling (LSP, formatter, linter) on a per-project basis. This skill guides the detection of project language/tooling, scaffolding of `.opencode.json` with appropriate settings, and optional creation of a project-local `flake.nix` devShell when the project needs Nix-managed dependencies.

## When to Use

- A project directory has no `.opencode.json` and the user wants to configure tooling
- The user asks to set up LSP, formatter, or linter for a specific language
- A new project is created and needs development environment configuration
- The user wants to add or change tooling for an existing project
- The project uses languages not covered by the global NixOS configuration

## Workflow

### Step 1: Detect Project Language/Tooling

Inspect the project root for language-specific files to determine what tooling is needed:

| Language | Indicator Files | Common LSP | Common Formatter | Common Linter |
|---|---|---|---|---|
| Nix | `*.nix`, `flake.nix` | `nil` | `alejandra`, `nixpkgs-fmt` | `statix`, `deadnix` |
| Python | `pyproject.toml`, `requirements.txt`, `setup.py` | `pyright`, `ruff-lsp` | `ruff`, `black` | `ruff`, `mypy` |
| Rust | `Cargo.toml` | `rust-analyzer` | `rustfmt` | `clippy` |
| JavaScript/TypeScript | `package.json`, `*.js`, `*.ts` | `typescript-language-server`, `vtsls` | `prettier`, `biome` | `eslint`, `biome` |
| Go | `go.mod` | `gopls` | `gofmt`, `goimports` | `golangci-lint` |
| C/C++ | `CMakeLists.txt`, `Makefile`, `*.c`, `*.cpp` | `clangd` | `clang-format` | `cppcheck`, `clang-tidy` |
| QML | `*.qml` | `qmlls` (from `qttools`) | `qmlformat` | `qmllint` |
| Lua | `*.lua` | `lua-language-server` | `stylua` | `luacheck` |
| Markdown | `*.md` | `marksman` | `mdformat` | `markdownlint` |
| YAML | `*.yaml`, `*.yml` | `yaml-language-server` | `yamlfmt` | `yamllint` |
| JSON | `*.json` | `json-language-server` (via `vscode-langservers-extracted`) | `jq`, `jsonfmt` | `jsonlint` |
| Bash | `*.sh` | `bash-language-server` | `shfmt` | `shellcheck` |
| Haskell | `*.hs`, `cabal.project` | `haskell-language-server` | `ormolu`, `fourmolu` | `hlint` |

**Detection rules:**
1. Check for `*.nix` files → Nix tooling
2. Check for `pyproject.toml` or `requirements.txt` → Python tooling
3. Check for `Cargo.toml` → Rust tooling
4. Check for `package.json` or `*.ts` files → JS/TS tooling
5. Check for `go.mod` → Go tooling
6. Check for `*.qml` → QML tooling
7. Check for other language-specific files as needed

### Step 2: Read Existing `.opencode.json` (if present)

If the project already has `.opencode.json`, read it first to understand existing configuration and preserve it.

### Step 3: Configure `.opencode.json`

Create or update `.opencode.json` in the project root. The minimal structure:

```json
{
  "lsp": {
    "<language-id>": {
      "command": ["<lsp-binary>", "<args>"],
      "root": "<project-root-marker>"
    }
  },
  "formatter": {
    "<language-id>": {
      "command": ["<formatter-binary>", "<args>"]
    }
  },
  "linter": {
    "<language-id>": {
      "command": ["<linter-binary>", "<args>"]
    }
  }
}
```

**Common configurations by language:**

#### Nix
```json
{
  "lsp": {
    "nix": {
      "command": ["nil", "--stdio"],
      "root": "flake.nix"
    }
  },
  "formatter": {
    "nix": {
      "command": ["alejandra", "-"]
    }
  },
  "linter": {
    "nix": {
      "command": ["statix", "check", "-i", "--stdin"]
    }
  }
}
```

#### Python
```json
{
  "lsp": {
    "python": {
      "command": ["ruff-lsp"],
      "root": "pyproject.toml"
    }
  },
  "formatter": {
    "python": {
      "command": ["ruff", "format", "-"]
    }
  },
  "linter": {
    "python": {
      "command": ["ruff", "check", "-"]
    }
  }
}
```

#### Rust
```json
{
  "lsp": {
    "rust": {
      "command": ["rust-analyzer"],
      "root": "Cargo.toml"
    }
  },
  "formatter": {
    "rust": {
      "command": ["rustfmt", "--emit", "stdout"]
    }
  },
  "linter": {
    "rust": {
      "command": ["clippy-driver", "--message-format=short"]
    }
  }
}
```

#### JavaScript/TypeScript
```json
{
  "lsp": {
    "javascript": {
      "command": ["typescript-language-server", "--stdio"],
      "root": "package.json"
    },
    "typescript": {
      "command": ["typescript-language-server", "--stdio"],
      "root": "package.json"
    }
  },
  "formatter": {
    "javascript": {
      "command": ["prettier", "--parser", "babel", "--stdin-filepath", "${file}"]
    },
    "typescript": {
      "command": ["prettier", "--parser", "typescript", "--stdin-filepath", "${file}"]
    }
  },
  "linter": {
    "javascript": {
      "command": ["eslint", "--stdin", "--stdin-filename", "${file}"]
    },
    "typescript": {
      "command": ["eslint", "--stdin", "--stdin-filename", "${file}"]
    }
  }
}
```

#### QML
```json
{
  "lsp": {
    "qml": {
      "command": ["qmlls"],
      "root": ".qml"
    }
  },
  "formatter": {
    "qml": {
      "command": ["qmlformat", "-"]
    }
  },
  "linter": {
    "qml": {
      "command": ["qmllint", "-"]
    }
  }
}
```

### Step 4: Check Global vs Project-Local Dependencies

**Rule:** If the required tools are already in the NixOS global configuration (e.g., `nil`, `alejandra` are already installed globally), skip to Step 5. If the tools are missing or a specific version is needed, create a project-local `flake.nix` devShell.

**How to check:**
1. Try `which <binary>` in the project directory
2. If the binary is not found, it needs to be added either globally (via NixOS config) or locally (via project flake)

**Decision:**
- **Global**: If the tool is commonly used across projects. Add to `~/nixos/modules/programs/...` and rebuild.
- **Local**: If the tool is project-specific or needs a specific version. Create `flake.nix` in the project root.

### Step 5: Create Project-Local `flake.nix` (when needed)

If project-local dependencies are needed, scaffold a minimal `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # LSP
            <lsp-package>
            # Formatter
            <formatter-package>
            # Linter
            <linter-package>
            # Other project-specific tools
            <other-tools>
          ];
        };
      });
}
```

**Example for a Python project:**
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            ruff-lsp
            ruff
            pyright
            python3
          ];
        };
      });
}
```

**After creating the flake:**
1. Run `nix develop` to enter the shell
2. OpenCode will pick up the tools from the PATH
3. The `.opencode.json` can reference these tools by binary name

### Step 6: Verify Configuration

1. Run `nix fmt` if the project is Nix-based
2. Open a file in the project and verify the LSP connects
3. Try formatting a file to verify the formatter works
4. Try linting to verify the linter works
5. If any tool fails, check the `.opencode.json` paths and command arguments

## NixOS-Specific Considerations

- **Global tools**: If a tool is needed across multiple projects, add it to `~/nixos/modules/programs/...` and rebuild with `sudo nixos-rebuild switch --flake .#xps`
- **Per-project tools**: Use `flake.nix` devShells for project-specific dependencies
- **No imperative installation**: Never use `pip install --user`, `npm install -g`, etc. Use Nix instead
- **Documentation**: If a new global tool is added, document it in `~/nixos/docs/<project-name>.md`

## Common Troubleshooting

| Problem | Solution |
|---|---|
| LSP not found | Check `which <lsp-binary>`; add to global config or project flake |
| Formatter not found | Same as above; check binary name and package name in nixpkgs |
| LSP connects but no diagnostics | Check linter configuration; some linters need separate activation |
| Multiple formatters conflict | Choose one per language; remove conflicting entries from `.opencode.json` |
| QML tools not found | `qmlls`, `qmlformat`, `qmllint` are in `pkgs.kdePackages.qttools` |
| Nix tools not found | `nil`, `alejandra`, `statix`, `deadnix` are in nixpkgs |

## References

- See `references/language-tooling-table.md` for an extended table of languages and their tools
- See `references/common-flakes.md` for copy-pasteable `flake.nix` templates for common languages
