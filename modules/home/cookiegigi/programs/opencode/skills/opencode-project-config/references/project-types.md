# Project Types Detection Matrix

This reference documents how `generate-config.py` detects project types and what configurations it generates for each.

## Detection Logic

The script uses two detection methods:
1. **File-based detection**: Checks for the existence of specific files (e.g., `Cargo.toml`, `package.json`)
2. **Extension-based detection**: Scans for files with specific extensions (e.g., `*.rs`, `*.py`)

A project type is considered detected if **either** method matches.

## Supported Project Types

| Project Type | Indicator Files | Extensions | Formatter | LSP Server | Nix Packages |
|-------------|----------------|------------|-----------|------------|--------------|
| **Rust** | `Cargo.toml`, `Cargo.lock` | `.rs` | `cargofmt` (`cargo fmt`) | `rust` (`rust-analyzer`) | `cargo`, `rustfmt`, `rust-analyzer` |
| **JavaScript/TypeScript** | `package.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lockb` | `.js`, `.jsx`, `.ts`, `.tsx`, `.mjs`, `.cjs`, `.mts`, `.cts` | `prettier` (if in package.json) or built-in | `typescript`, `eslint` | `nodejs`, `typescript` |
| **Python** | `requirements.txt`, `pyproject.toml`, `setup.py`, `setup.cfg`, `Pipfile`, `poetry.lock` | `.py`, `.pyi` | `ruff` (if available) or `black` | `pyright` | `python3`, `ruff`, `pyright` |
| **Go** | `go.mod`, `go.sum` | `.go` | `gofmt` | `gopls` | `go`, `gopls` |
| **Nix** | `flake.nix`, `default.nix`, `shell.nix` | `.nix` | `nixfmt` | `nixd` | `nixfmt`, `nixd` |
| **PHP** | `composer.json`, `composer.lock` | `.php` | `pint` (if in composer.json) | `php intelephense` | `php`, `phpPackages.intelephense` |
| **Java** | `pom.xml`, `build.gradle`, `build.gradle.kts` | `.java` | Built-in | `jdtls` | `jdk`, `jdt-language-server` |
| **Elixir** | `mix.exs` | `.ex`, `.exs` | `mix` (`mix format`) | `elixir-ls` | `elixir`, `elixir-ls` |
| **Haskell** | `*.cabal`, `stack.yaml`, `package.yaml` | `.hs`, `.lhs` | `ormolu` | `hls` (`haskell-language-server-wrapper`) | `ghc`, `ormolu`, `haskell-language-server` |
| **Clojure** | `project.clj`, `deps.edn` | `.clj`, `.cljs`, `.cljc`, `.edn` | `cljfmt` | `clojure-lsp` | `clojure`, `cljfmt`, `clojure-lsp` |
| **Dart** | `pubspec.yaml` | `.dart` | `dart` (`dart format`) | `dart` | `dart` |
| **Zig** | `build.zig` | `.zig`, `.zon` | `zig` (`zig fmt`) | `zls` | `zig`, `zls` |
| **Gleam** | `gleam.toml` | `.gleam` | `gleam` (`gleam format`) | `gleam` | `gleam` |
| **Ruby** | `Gemfile`, `Gemfile.lock` | `.rb`, `.rake`, `.gemspec`, `.ru` | `standardrb` or `rubocop` | `ruby-lsp` | `ruby`, `ruby-lsp`, `rubocop` |
| **Kotlin** | `build.gradle.kts` | `.kt`, `.kts` | Built-in | `kotlin-ls` | `kotlin`, `kotlin-language-server` |
| **Bash** | — | `.sh`, `.bash`, `.zsh`, `.ksh` | `shfmt` | `bash` (`bash-language-server`) | `shfmt`, `nodePackages.bash-language-server` |
| **Terraform** | — | `.tf`, `.tfvars` | `terraform` (`terraform fmt`) | `terraform` | `terraform` |
| **Swift** | `Package.swift` | `.swift` | Built-in | `sourcekit-lsp` | `swift` |
| **C# / F#** | `*.csproj`, `*.fsproj`, `*.sln` | `.cs`, `.csx`, `.fs`, `.fsi`, `.fsx`, `.fsscript` | Built-in | `csharp` / `fsharp` | `dotnet-sdk` |
| **C / C++** | `Makefile`, `CMakeLists.txt` | `.c`, `.cpp`, `.cc`, `.cxx`, `.c++`, `.h`, `.hpp`, `.hh`, `.hxx`, `.h++` | `clang-format` | `clangd` | `clang-tools` |
| **OCaml** | `dune-project` | `.ml`, `.mli` | `ocamlformat` | `ocaml-lsp` | `ocamlformat`, `ocamlPackages.ocaml-lsp` |
| **D** | `dub.json`, `dub.sdl` | `.d` | `dfmt` | Built-in | `dtools` |
| **Typst** | — | `.typ`, `.typc` | Built-in | `tinymist` | `tinymist` |
| **Vue** | — | `.vue` | Built-in | `vue` | `vue-language-server` |
| **Svelte** | — | `.svelte` | Built-in | `svelte` | `svelte-language-server` |
| **Prisma** | — | `.prisma` | Built-in | `prisma` | `prisma` |
| **Astro** | — | `.astro` | Built-in | `astro` | `astro-language-server` |

## Formatter Config Examples

### Rust
```json
{
  "formatter": {
    "cargofmt": {
      "command": ["cargo", "fmt", "--"],
      "extensions": [".rs"]
    }
  }
}
```

### JavaScript/TypeScript (with Prettier)
```json
{
  "formatter": {
    "prettier": {
      "command": ["npx", "prettier", "--write", "$FILE"],
      "extensions": [".js", ".jsx", ".ts", ".tsx", ".html", ".css", ".md", ".json", ".yaml"]
    }
  }
}
```

### Python (with Ruff)
```json
{
  "formatter": {
    "ruff": {
      "command": ["ruff", "format", "$FILE"],
      "extensions": [".py", ".pyi"]
    }
  }
}
```

### Go
```json
{
  "formatter": {
    "gofmt": {
      "command": ["gofmt", "-w", "$FILE"],
      "extensions": [".go"]
    }
  }
}
```

### Nix
```json
{
  "formatter": {
    "nixfmt": {
      "command": ["nixfmt", "$FILE"],
      "extensions": [".nix"]
    }
  }
}
```

## LSP Config Examples

### Rust
```json
{
  "lsp": {
    "rust": {
      "command": ["rust-analyzer"],
      "extensions": [".rs"]
    }
  }
}
```

### JavaScript/TypeScript
```json
{
  "lsp": {
    "typescript": {
      "command": ["typescript-language-server", "--stdio"],
      "extensions": [".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".mts", ".cts"]
    }
  }
}
```

### Python
```json
{
  "lsp": {
    "pyright": {
      "command": ["pyright-langserver", "--stdio"],
      "extensions": [".py", ".pyi"]
    }
  }
}
```

### Go
```json
{
  "lsp": {
    "gopls": {
      "command": ["gopls"],
      "extensions": [".go"]
    }
  }
}
```

### Nix
```json
{
  "lsp": {
    "nixd": {
      "command": ["nixd"],
      "extensions": [".nix"]
    }
  }
}
```

## Flake.nix DevShell Pattern

When the script generates a `flake.nix`, it uses this pattern:

```nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          # Detected packages go here
        ];
      };
    };
}
```

If a `flake.nix` already exists, the script prints the list of packages to add to `buildInputs` instead of overwriting.

## Important Notes

- The script generates **explicit** formatter/LSP configs rather than using `formatter: true` or `lsp: true`. This avoids ambiguity and prevents OpenCode from trying to run irrelevant tools.
- For JavaScript/TypeScript projects, the script checks `package.json` for `prettier` or `eslint` dependencies and configures them accordingly.
- For Python projects, `ruff` is preferred if available, falling back to `black`.
- For Ruby projects, `standardrb` is preferred, falling back to `rubocop`.
- Some LSP servers auto-install (e.g., `astro`, `bash`, `kotlin-ls`, `lua-ls`, `svelte`, `vue`, `yaml-ls`). The script still adds the corresponding Nix package for reliability.
- The `$FILE` placeholder in formatter commands is replaced by OpenCode with the path to the file being formatted.
