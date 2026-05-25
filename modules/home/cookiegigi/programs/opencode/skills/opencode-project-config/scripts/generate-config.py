#!/usr/bin/env python3
"""
OpenCode Project Configuration Generator

Auto-detects project language/tooling and generates:
1. .opencode.json with explicit formatter and LSP configurations
2. flake.nix devShell with required Nix packages (or prints packages to add)

Usage:
    python3 generate-config.py [project-root]

If project-root is omitted, uses the current working directory.
"""

import json
import os
import sys
from pathlib import Path


# Detection rules: maps project type to indicator files and extensions
DETECTION_RULES = {
    "rust": {
        "files": ["Cargo.toml", "Cargo.lock"],
        "extensions": [".rs"],
    },
    "javascript": {
        "files": ["package.json", "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb"],
        "extensions": [".js", ".jsx", ".mjs", ".cjs"],
    },
    "typescript": {
        "files": ["package.json", "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb"],
        "extensions": [".ts", ".tsx", ".mts", ".cts"],
    },
    "python": {
        "files": ["requirements.txt", "pyproject.toml", "setup.py", "setup.cfg", "Pipfile", "poetry.lock"],
        "extensions": [".py", ".pyi"],
    },
    "go": {
        "files": ["go.mod", "go.sum"],
        "extensions": [".go"],
    },
    "nix": {
        "files": ["flake.nix", "default.nix", "shell.nix"],
        "extensions": [".nix"],
    },
    "php": {
        "files": ["composer.json", "composer.lock"],
        "extensions": [".php"],
    },
    "java": {
        "files": ["pom.xml", "build.gradle", "build.gradle.kts"],
        "extensions": [".java"],
    },
    "elixir": {
        "files": ["mix.exs"],
        "extensions": [".ex", ".exs"],
    },
    "haskell": {
        "files": ["stack.yaml", "package.yaml"],
        "extensions": [".hs", ".lhs"],
    },
    "clojure": {
        "files": ["project.clj", "deps.edn"],
        "extensions": [".clj", ".cljs", ".cljc", ".edn"],
    },
    "dart": {
        "files": ["pubspec.yaml"],
        "extensions": [".dart"],
    },
    "zig": {
        "files": ["build.zig"],
        "extensions": [".zig", ".zon"],
    },
    "gleam": {
        "files": ["gleam.toml"],
        "extensions": [".gleam"],
    },
    "ruby": {
        "files": ["Gemfile", "Gemfile.lock"],
        "extensions": [".rb", ".rake", ".gemspec", ".ru"],
    },
    "kotlin": {
        "files": ["build.gradle.kts"],
        "extensions": [".kt", ".kts"],
    },
    "bash": {
        "files": [],
        "extensions": [".sh", ".bash", ".zsh", ".ksh"],
    },
    "terraform": {
        "files": [],
        "extensions": [".tf", ".tfvars"],
    },
    "swift": {
        "files": ["Package.swift"],
        "extensions": [".swift", ".objc", ".objcpp"],
    },
    "csharp": {
        "files": [],
        "extensions": [".cs", ".csx"],
    },
    "fsharp": {
        "files": [],
        "extensions": [".fs", ".fsi", ".fsx", ".fsscript"],
    },
    "cpp": {
        "files": ["Makefile", "CMakeLists.txt"],
        "extensions": [".c", ".cpp", ".cc", ".cxx", ".c++", ".h", ".hpp", ".hh", ".hxx", ".h++"],
    },
    "ocaml": {
        "files": ["dune-project"],
        "extensions": [".ml", ".mli"],
    },
    "d": {
        "files": ["dub.json", "dub.sdl"],
        "extensions": [".d"],
    },
    "typst": {
        "files": [],
        "extensions": [".typ", ".typc"],
    },
    "vue": {
        "files": [],
        "extensions": [".vue"],
    },
    "svelte": {
        "files": [],
        "extensions": [".svelte"],
    },
    "prisma": {
        "files": [],
        "extensions": [".prisma"],
    },
    "astro": {
        "files": [],
        "extensions": [".astro"],
    },
}


# Formatter configurations per project type
FORMATTER_CONFIGS = {
    "rust": {
        "cargofmt": {
            "command": ["cargo", "fmt", "--"],
            "extensions": [".rs"],
        }
    },
    "javascript": {
        "prettier": {
            "command": ["npx", "prettier", "--write", "$FILE"],
            "extensions": [".js", ".jsx", ".mjs", ".cjs", ".html", ".css", ".md", ".json", ".yaml"],
        }
    },
    "typescript": {
        "prettier": {
            "command": ["npx", "prettier", "--write", "$FILE"],
            "extensions": [".ts", ".tsx", ".mts", ".cts", ".js", ".jsx", ".mjs", ".cjs", ".html", ".css", ".md", ".json", ".yaml"],
        }
    },
    "python": {
        "ruff": {
            "command": ["ruff", "format", "$FILE"],
            "extensions": [".py", ".pyi"],
        }
    },
    "go": {
        "gofmt": {
            "command": ["gofmt", "-w", "$FILE"],
            "extensions": [".go"],
        }
    },
    "nix": {
        "nixfmt": {
            "command": ["nixfmt", "$FILE"],
            "extensions": [".nix"],
        }
    },
    "php": {
        "pint": {
            "command": ["pint", "$FILE"],
            "extensions": [".php"],
        }
    },
    "elixir": {
        "mix": {
            "command": ["mix", "format", "$FILE"],
            "extensions": [".ex", ".exs", ".eex", ".heex", ".leex", ".neex", ".sface"],
        }
    },
    "haskell": {
        "ormolu": {
            "command": ["ormolu", "--mode", "inplace", "$FILE"],
            "extensions": [".hs", ".lhs"],
        }
    },
    "clojure": {
        "cljfmt": {
            "command": ["cljfmt", "fix", "$FILE"],
            "extensions": [".clj", ".cljs", ".cljc", ".edn"],
        }
    },
    "dart": {
        "dart": {
            "command": ["dart", "format", "$FILE"],
            "extensions": [".dart"],
        }
    },
    "zig": {
        "zig": {
            "command": ["zig", "fmt", "$FILE"],
            "extensions": [".zig", ".zon"],
        }
    },
    "gleam": {
        "gleam": {
            "command": ["gleam", "format", "$FILE"],
            "extensions": [".gleam"],
        }
    },
    "ruby": {
        "standardrb": {
            "command": ["standardrb", "--fix", "$FILE"],
            "extensions": [".rb", ".rake", ".gemspec", ".ru"],
        }
    },
    "bash": {
        "shfmt": {
            "command": ["shfmt", "-w", "$FILE"],
            "extensions": [".sh", ".bash", ".zsh", ".ksh"],
        }
    },
    "terraform": {
        "terraform": {
            "command": ["terraform", "fmt", "$FILE"],
            "extensions": [".tf", ".tfvars"],
        }
    },
    "d": {
        "dfmt": {
            "command": ["dfmt", "$FILE"],
            "extensions": [".d"],
        }
    },
    "cpp": {
        "clang-format": {
            "command": ["clang-format", "-i", "$FILE"],
            "extensions": [".c", ".cpp", ".cc", ".cxx", ".c++", ".h", ".hpp", ".hh", ".hxx", ".h++"],
        }
    },
    "ocaml": {
        "ocamlformat": {
            "command": ["ocamlformat", "-i", "$FILE"],
            "extensions": [".ml", ".mli"],
        }
    },
    "csharp": {},
    "fsharp": {},
    "java": {},
    "kotlin": {},
    "swift": {},
    "typst": {},
    "vue": {},
    "svelte": {},
    "prisma": {},
    "astro": {},
}


# LSP configurations per project type
LSP_CONFIGS = {
    "rust": {
        "rust": {
            "command": ["rust-analyzer"],
            "extensions": [".rs"],
        }
    },
    "javascript": {
        "typescript": {
            "command": ["typescript-language-server", "--stdio"],
            "extensions": [".js", ".jsx", ".mjs", ".cjs", ".ts", ".tsx", ".mts", ".cts"],
        },
        "eslint": {
            "command": ["vscode-eslint-language-server", "--stdio"],
            "extensions": [".js", ".jsx", ".mjs", ".cjs", ".ts", ".tsx", ".mts", ".cts", ".vue"],
        }
    },
    "typescript": {
        "typescript": {
            "command": ["typescript-language-server", "--stdio"],
            "extensions": [".ts", ".tsx", ".mts", ".cts", ".js", ".jsx", ".mjs", ".cjs"],
        },
        "eslint": {
            "command": ["vscode-eslint-language-server", "--stdio"],
            "extensions": [".ts", ".tsx", ".mts", ".cts", ".js", ".jsx", ".mjs", ".cjs", ".vue"],
        }
    },
    "python": {
        "pyright": {
            "command": ["pyright-langserver", "--stdio"],
            "extensions": [".py", ".pyi"],
        }
    },
    "go": {
        "gopls": {
            "command": ["gopls"],
            "extensions": [".go"],
        }
    },
    "nix": {
        "nixd": {
            "command": ["nixd"],
            "extensions": [".nix"],
        }
    },
    "php": {
        "php intelephense": {
            "command": ["intelephense", "--stdio"],
            "extensions": [".php"],
        }
    },
    "java": {
        "jdtls": {
            "command": ["jdtls"],
            "extensions": [".java"],
        }
    },
    "elixir": {
        "elixir-ls": {
            "command": ["elixir-ls"],
            "extensions": [".ex", ".exs"],
        }
    },
    "haskell": {
        "hls": {
            "command": ["haskell-language-server-wrapper", "--lsp"],
            "extensions": [".hs", ".lhs"],
        }
    },
    "clojure": {
        "clojure-lsp": {
            "command": ["clojure-lsp"],
            "extensions": [".clj", ".cljs", ".cljc", ".edn"],
        }
    },
    "dart": {
        "dart": {
            "command": ["dart", "language-server", "--protocol=lsp"],
            "extensions": [".dart"],
        }
    },
    "zig": {
        "zls": {
            "command": ["zls"],
            "extensions": [".zig", ".zon"],
        }
    },
    "gleam": {
        "gleam": {
            "command": ["gleam", "lsp"],
            "extensions": [".gleam"],
        }
    },
    "ruby": {
        "ruby-lsp": {
            "command": ["ruby-lsp"],
            "extensions": [".rb", ".rake", ".gemspec", ".ru"],
        }
    },
    "kotlin": {
        "kotlin-ls": {
            "command": ["kotlin-language-server"],
            "extensions": [".kt", ".kts"],
        }
    },
    "bash": {
        "bash": {
            "command": ["bash-language-server", "start"],
            "extensions": [".sh", ".bash", ".zsh", ".ksh"],
        }
    },
    "terraform": {
        "terraform": {
            "command": ["terraform-ls", "serve"],
            "extensions": [".tf", ".tfvars"],
        }
    },
    "swift": {
        "sourcekit-lsp": {
            "command": ["sourcekit-lsp"],
            "extensions": [".swift", ".objc", ".objcpp"],
        }
    },
    "csharp": {
        "csharp": {
            "command": ["csharp-ls"],
            "extensions": [".cs", ".csx"],
        }
    },
    "fsharp": {
        "fsharp": {
            "command": ["fsautocomplete", "--stdio"],
            "extensions": [".fs", ".fsi", ".fsx", ".fsscript"],
        }
    },
    "cpp": {
        "clangd": {
            "command": ["clangd"],
            "extensions": [".c", ".cpp", ".cc", ".cxx", ".c++", ".h", ".hpp", ".hh", ".hxx", ".h++"],
        }
    },
    "ocaml": {
        "ocaml-lsp": {
            "command": ["ocamllsp"],
            "extensions": [".ml", ".mli"],
        }
    },
    "d": {},
    "typst": {
        "tinymist": {
            "command": ["tinymist"],
            "extensions": [".typ", ".typc"],
        }
    },
    "vue": {
        "vue": {
            "command": ["vue-language-server", "--stdio"],
            "extensions": [".vue"],
        }
    },
    "svelte": {
        "svelte": {
            "command": ["svelte-language-server", "--stdio"],
            "extensions": [".svelte"],
        }
    },
    "prisma": {
        "prisma": {
            "command": ["prisma-language-server", "--stdio"],
            "extensions": [".prisma"],
        }
    },
    "astro": {
        "astro": {
            "command": ["astro-ls", "--stdio"],
            "extensions": [".astro"],
        }
    },
}


# Nix packages per project type
NIX_PACKAGES = {
    "rust": ["cargo", "rustfmt", "rust-analyzer"],
    "javascript": ["nodejs", "typescript"],
    "typescript": ["nodejs", "typescript"],
    "python": ["python3", "ruff", "pyright"],
    "go": ["go", "gopls"],
    "nix": ["nixfmt-rfc-style", "nixd"],
    "php": ["php", "phpPackages.intelephense"],
    "java": ["jdk", "jdt-language-server"],
    "elixir": ["elixir", "elixir-ls"],
    "haskell": ["ghc", "ormolu", "haskell-language-server"],
    "clojure": ["clojure", "cljfmt", "clojure-lsp"],
    "dart": ["dart"],
    "zig": ["zig", "zls"],
    "gleam": ["gleam"],
    "ruby": ["ruby", "ruby-lsp", "rubocop"],
    "kotlin": ["kotlin", "kotlin-language-server"],
    "bash": ["shfmt", "nodePackages.bash-language-server"],
    "terraform": ["terraform", "terraform-ls"],
    "swift": ["swift"],
    "csharp": ["dotnet-sdk", "csharp-ls"],
    "fsharp": ["dotnet-sdk", "fsautocomplete"],
    "cpp": ["clang-tools"],
    "ocaml": ["ocamlformat", "ocamlPackages.ocaml-lsp"],
    "d": ["dtools"],
    "typst": ["tinymist"],
    "vue": ["vue-language-server"],
    "svelte": ["svelte-language-server"],
    "prisma": ["prisma"],
    "astro": ["astro-language-server"],
}


def detect_project_types(project_root):
    """Detect project types based on files and extensions."""
    detected = set()
    root = Path(project_root).resolve()

    # Check for indicator files
    for proj_type, rules in DETECTION_RULES.items():
        for filename in rules["files"]:
            if (root / filename).exists():
                detected.add(proj_type)
                break

    # Check for extensions (only if not already detected by files)
    for proj_type, rules in DETECTION_RULES.items():
        if proj_type in detected:
            continue
        for ext in rules["extensions"]:
            # Search up to 3 levels deep for files with this extension
            found = False
            for depth in range(4):
                pattern = "*/" * depth + f"*{ext}"
                if list(root.glob(pattern)):
                    detected.add(proj_type)
                    found = True
                    break
            if found:
                break

    return sorted(detected)


def check_js_tooling(project_root):
    """Check for prettier/eslint in package.json."""
    package_json = Path(project_root) / "package.json"
    if not package_json.exists():
        return {}, {}

    try:
        with open(package_json) as f:
            pkg = json.load(f)
    except (json.JSONDecodeError, IOError):
        return {}, {}

    deps = {**pkg.get("dependencies", {}), **pkg.get("devDependencies", {})}
    formatters = {}
    lsps = {}

    if "prettier" in deps:
        formatters["prettier"] = {
            "command": ["npx", "prettier", "--write", "$FILE"],
            "extensions": [".js", ".jsx", ".ts", ".tsx", ".html", ".css", ".md", ".json", ".yaml", ".yml"],
        }

    if "eslint" in deps or "typescript" in deps:
        lsps["eslint"] = {
            "command": ["vscode-eslint-language-server", "--stdio"],
            "extensions": [".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".mts", ".cts", ".vue"],
        }

    return formatters, lsps


def generate_opencode_json(project_root, detected_types):
    """Generate .opencode.json content."""
    formatters = {}
    lsps = {}

    # Handle JS/TS tooling specially
    js_formatters, js_lsps = check_js_tooling(project_root)

    for proj_type in detected_types:
        # Add formatters
        if proj_type in ["javascript", "typescript"] and js_formatters:
            formatters.update(js_formatters)
        elif proj_type in FORMATTER_CONFIGS and FORMATTER_CONFIGS[proj_type]:
            formatters.update(FORMATTER_CONFIGS[proj_type])

        # Add LSPs
        if proj_type in ["javascript", "typescript"] and js_lsps:
            lsps.update(js_lsps)
        elif proj_type in LSP_CONFIGS and LSP_CONFIGS[proj_type]:
            lsps.update(LSP_CONFIGS[proj_type])

    config: dict[str, object] = {
        "$schema": "https://opencode.ai/config.json",
        "_comment": f"Auto-generated by opencode-project-config skill. Detected types: {', '.join(detected_types)}",
    }

    if formatters:
        config["formatter"] = formatters

    if lsps:
        config["lsp"] = lsps

    return config


def generate_flake_nix(detected_types):
    """Generate flake.nix content."""
    packages = set()
    for proj_type in detected_types:
        if proj_type in NIX_PACKAGES:
            packages.update(NIX_PACKAGES[proj_type])

    packages_list = sorted(packages)

    flake_content = f'''{{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {{ self, nixpkgs }}:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${{system}};
    in {{
      devShells.${{system}}.default = pkgs.mkShell {{
        buildInputs = with pkgs; [
          {"\n          ".join(packages_list)}
        ];
      }};
    }};
}}
'''

    return flake_content, packages_list


def main():
    project_root = sys.argv[1] if len(sys.argv) > 1 else "."
    project_root = Path(project_root).resolve()

    if not project_root.is_dir():
        print(f"Error: Not a directory: {project_root}")
        sys.exit(1)

    print(f"Scanning project: {project_root}")
    print()

    detected = detect_project_types(project_root)

    if not detected:
        print("No known project types detected.")
        print("Supported types: rust, javascript, typescript, python, go, nix, php, java, elixir,")
        print("  haskell, clojure, dart, zig, gleam, ruby, kotlin, bash, terraform, swift,")
        print("  csharp, fsharp, cpp, ocaml, d, typst, vue, svelte, prisma, astro")
        print()
        print("To manually configure, create .opencode.json with explicit formatter and lsp entries.")
        sys.exit(0)

    print(f"Detected project types: {', '.join(detected)}")
    print()

    # Generate .opencode.json
    opencode_config = generate_opencode_json(project_root, detected)
    opencode_path = project_root / ".opencode.json"

    if opencode_path.exists():
        print(f"WARNING: {opencode_path} already exists.")
        print("Generated config (merge manually):")
        print(json.dumps(opencode_config, indent=2))
    else:
        with open(opencode_path, "w") as f:
            json.dump(opencode_config, f, indent=2)
            f.write("\n")
        print(f"Created: {opencode_path}")

    print()

    # Generate or suggest flake.nix
    flake_path = project_root / "flake.nix"
    flake_content, packages = generate_flake_nix(detected)

    if flake_path.exists():
        print(f"WARNING: {flake_path} already exists.")
        print("Add the following packages to your devShell buildInputs:")
        print()
        for pkg in packages:
            print(f"  {pkg}")
    else:
        with open(flake_path, "w") as f:
            f.write(flake_content)
        print(f"Created: {flake_path}")

    print()
    print("Next steps:")
    print("1. Review .opencode.json and flake.nix")
    print("2. Run 'nix develop' to enter the dev shell with required tools")
    print("3. Verify with: opencode lsp list")


if __name__ == "__main__":
    main()
