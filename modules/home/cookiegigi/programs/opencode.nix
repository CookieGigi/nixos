# WARN: This file is the single source of truth for the global OpenCode configuration.
# Always edit THIS Nix file; the live ~/.config/opencode files are generated from here.
# Nix is the source of truth for global config.
{pkgs, ...}: let
  opencodeConfig = (pkgs.formats.json {}).generate "opencode.json" {
    agent = {
      explaining = {
        model = "opencode-go/kimi-k2.6";
        mode = "primary";
        description = "Read and execute non-destructive commands to answer questions in a pedagogical way";
        prompt = ''
          You are a pedagogical explaining agent. Your goal is to help the user understand concepts by reading relevant files and executing safe, non-destructive commands.
          Never edit or delete files. Always explain your reasoning step by step. Use bash, read, glob, grep, webfetch, and websearch tools as needed.
          When running commands, prefer read-only operations (cat, ls, grep, find, etc.). Avoid any command that modifies the filesystem.
        '';
        permission = {
          read = "allow";
          bash = "allow";
          glob = "allow";
          grep = "allow";
          webfetch = "allow";
          websearch = "allow";
          task = "allow";
          lsp = "allow";
          skill = "allow";
          question = "allow";
          todowrite = "allow";
          edit = "deny";
          external_directory = "ask";
        };
        steps = 20;
        color = "info";
      };

      configuration = {
        model = "opencode-go/deepseek-v4-pro";
        mode = "primary";
        description = "Nix/NixOS and project configuration expert that stays in the Nix way";
        prompt = ''
          You are a Nix and system configuration expert. You help with NixOS configuration, Nix flakes, and project setup following Nix conventions.
          You prefer declarative configuration over imperative changes. When suggesting edits to Nix files, ensure they follow the existing style (alejandra formatting) and use proper Nix patterns.
          Always suggest changes that fit within the existing module structure. Use read, bash, glob, grep, and lsp tools to explore the codebase before making recommendations.
        '';
        permission = {
          read = "allow";
          bash = "allow";
          glob = "allow";
          grep = "allow";
          webfetch = "allow";
          websearch = "allow";
          task = "allow";
          lsp = "allow";
          skill = "allow";
          question = "allow";
          todowrite = "allow";
          edit = "ask";
          external_directory = "ask";
        };
        steps = 20;
        color = "success";
      };

      git-commit = {
        model = "opencode-go/deepseek-v4-flash";
        mode = "subagent";
        description = "Git commit specialist following the Conventional Commits specification";
        prompt = ''
          You are a git commit specialist. Your job is to craft well-formed, meaningful commit messages that follow the **Conventional Commits 1.0.0** specification (https://www.conventionalcommits.org/en/v1.0.0/).

          ## Commit Message Format

          ```
          <type>[optional scope]: <description>

          [optional body]

          [optional footer(s)]
          ```

          ### Structural Elements

          1. **type** — REQUIRED. A noun describing the kind of change:
             - `feat` — a new feature (correlates with MINOR in SemVer)
             - `fix` — a bug fix (correlates with PATCH in SemVer)
             - `docs` — documentation only changes
             - `style` — formatting, missing semicolons, etc; no code change
             - `refactor` — code change that neither fixes a bug nor adds a feature
             - `perf` — performance improvement
             - `test` — adding missing tests or correcting existing tests
             - `build` — changes to the build system or external dependencies
             - `ci` — changes to CI configuration files and scripts
             - `chore` — routine tasks, maintenance, dependency updates, etc.
             - `revert` — reversion of a previous commit

          2. **scope** — OPTIONAL. A noun in parentheses describing the section affected, e.g., `feat(parser): add ability to parse arrays`

          3. **!** — OPTIONAL. Append before the colon to indicate a BREAKING CHANGE, e.g., `feat(api)!: drop support for v1`

          4. **description** — REQUIRED. Short imperative summary (max 72 chars). Start with lowercase. No period at the end.

          5. **body** — OPTIONAL. One blank line after description. Free-form paragraphs with additional context. Wrap at 72 chars.

          6. **footer(s)** — OPTIONAL. One blank line after body (or description if no body). Format: `token: value` or `token #value`. Use `BREAKING CHANGE:` to describe breaking changes (MUST be uppercase).

          ### Key Rules

          - Always use **imperative mood**: "add" not "added", "fix" not "fixed"
          - Description MUST immediately follow the colon and space
          - `BREAKING CHANGE` MUST be uppercase
          - `BREAKING CHANGE:` in footer and `!` in prefix are both valid for breaking changes
          - Keep descriptions brief (under 72 characters)

          ## Your Workflow

          When asked to create a commit, follow these steps:

          1. **Inspect the state**: Run `git status` to see staged and unstaged changes. Run `git diff --staged` to review what will be committed. If nothing is staged, run `git diff` to see working tree changes.

          2. **Check history**: Run `git log --oneline -10` to understand the project's commit message style. Adapt the scope naming and level of detail to match existing conventions.

          3. **Classify the change**: Based on the diff, determine the most appropriate type(s). If the changes mix multiple types, recommend splitting into multiple commits.

          4. **Craft the message**: Write a Conventional Commits message with:
             - Proper type and optional scope
             - Concise, imperative description (≤72 chars)
             - Body paragraphs if the change needs explanation
             - Footer for breaking changes, issue references, or co-authors

          5. **Present for review**: Show the proposed commit message to the user. Ask for explicit confirmation before executing `git commit`.

          6. **Execute**: Run `git commit -m "..."` (or `git commit -F` for multi-line messages). Confirm the commit succeeded by running `git log -1 --oneline`.

          ## Safety Rules

          - **NEVER commit without explicit user confirmation**. Always present the message first and wait for approval.
          - NEVER run `git commit --amend` unless the user explicitly requests it.
          - NEVER force push (`git push --force`) to main/master. Warn the user if they request it.
          - NEVER skip hooks (`--no-verify`, `--no-gpg-sign`) unless the user explicitly requests it.
          - NEVER run destructive operations (hard reset, etc.) without explicit user request.
          - If the commit fails (e.g., pre-commit hook rejection), report the error and let the user decide how to proceed. Do NOT automatically amend and retry.
          - Do not stage files (`git add`) unless the user asks you to. Only commit what is already staged.

          ## Example Commit Messages

          Simple fix:
          ```
          fix: prevent racing of requests
          ```

          Feature with scope:
          ```
          feat(auth): add OAuth2 login support
          ```

          Breaking change:
          ```
          feat!: drop support for Node 14

          BREAKING CHANGE: This release requires Node.js 16 or later.
          ```

          Revert:
          ```
          revert: let us never again speak of the noodle incident

          Refs: 676104e, a215868
          ```
        '';
        permission = {
          read = "allow";
          bash = "allow";
          glob = "allow";
          grep = "allow";
          webfetch = "deny";
          websearch = "deny";
          task = "allow";
          lsp = "deny";
          skill = "allow";
          question = "allow";
          todowrite = "deny";
          edit = "deny";
          external_directory = "ask";
        };
        steps = 15;
        color = "success";
      };
    };

    model = "opencode-go/kimi-k2.6";
    small_model = "opencode-go/deepseek-v4-flash";
    default_agent = "build";

    tui = {
      theme = "catppuccin";
    };

    tools = {
      lsp = true;
    };

    formatter = {
      nix = {
        command = ["nix" "fmt" "."];
        extensions = [".nix"];
      };
    };

    lsp = {
      nix = {
        command = ["${pkgs.nil}/bin/nil"];
        extensions = [".nix"];
      };
    };

    mcp = {
      duckduckgo = {
        type = "local";
        command = ["npx" "-y" "duckduckgo-mcp-server"];
        enabled = true;
      };
      context7 = {
        type = "remote";
        url = "https://mcp.context7.com/mcp";
        enabled = true;
      };
    };

    skills = {
      paths = ["/home/cookiegigi/.config/opencode/skills"];
    };

    plugin = ["@tarquinen/opencode-dcp@latest"];

    username = "cookiegigi";
  };

  agentsMd = pkgs.writeText "AGENTS.md" ''
    > **Note:** This global `~/.config/opencode` directory is managed by the NixOS configuration (`modules/programs/opencode.nix`). Do not edit files here manually -- changes will be overwritten on the next `nixos-rebuild`.

    # AGENTS.md -- Global Agent Context

    ## System Overview

    This machine runs **NixOS**, a declarative Linux distribution managed entirely through configuration files. All system-level software, services, kernel modules, and user environments are defined in `.nix` files and applied atomically via `nixos-rebuild`.

    - **No imperative package management**: Do not use `apt`, `brew`, `pip --user`, `npm -g`, or manual installations for system-wide tools.
    - **Everything is in the flake**: If a tool or service is needed system-wide, it must be declared in the NixOS configuration repository and rebuilt.
    - **Home directory is ephemeral**: The root filesystem is tmpfs (impermanence). Persistent data must be explicitly declared in `environment.persistence."/persist"` or it will be lost on reboot.

    ## NixOS Configuration Repository

    The system configuration lives in `~/nixos/`:
    - **Flake-based**, uses `nixos-unstable`
    - **Host**: `xps` (x86_64-linux)
    - **Entrypoint**: `flake.nix`
    - **Modules**: `modules/` contains reusable NixOS modules (core, desktop, audio, programs, users, etc.)
    - **Host-specific**: `hosts/xps/` contains hardware and disk configuration
    - **Impermanence**: `/` is tmpfs; persistent data lives on BTRFS subvolume `@persist` mounted at `/persist`
    - **Disko**: declarative disk layout (LUKS + BTRFS)

    ### Key Commands
    - Apply config: `sudo nixos-rebuild switch --flake ~/nixos#xps`
    - Build without switching: `sudo nixos-rebuild build --flake ~/nixos#xps`
    - Check flake: `nix flake check ~/nixos`
    - Format `.nix` files: `nix fmt ~/nixos` (uses alejandra)

    ## Working on Projects

    When working on a project *outside* the NixOS config repository:

    ### System-wide packages or global configuration
    If a project needs a tool, service, or system-level config that affects the whole machine:

    1. **Do NOT install imperatively** (no `apt`, `brew`, `pip install --user`, `npm install -g`, etc.)
    2. **Add it to the NixOS flake** in the appropriate module under `~/nixos/modules/` (e.g., `modules/programs/...`, `modules/users/cookiegigi.nix`)
    3. **Document it** in `~/nixos/docs/<project-name>.md` so the dependency is tracked
    4. **Rebuild** with `sudo nixos-rebuild switch --flake ~/nixos#xps`

    ### Project-local tools or language dependencies
    Prefer keeping dependencies local to the project when possible:

    - Use `flake.nix` / `shell.nix` within the project for development shells
    - Use language-specific lockfiles (`package-lock.json`, `Cargo.lock`, `poetry.lock`, `go.mod`, etc.)
    - Use project-local package managers
    - Use container tools (`docker`, `podman`) if the project already supports them

    ### Rule of Thumb
    - **Affects the whole system or needs to persist across reboots** -> belongs in `~/nixos`
    - **Only matters while working inside a specific project** -> keep it local to that project

    ## Agent Behavior Rules

    - **Never execute `sudo nixos-rebuild` yourself**. Always ask the user for explicit permission before running any `nixos-rebuild` command (switch, build, test, etc.). The user must approve each rebuild.

    ## Important Warnings

    - `hardware-configuration.nix` is auto-generated -- do not edit it manually
    - `boot.kernelPackages = pkgs.linuxPackages_latest` tracks the latest kernel, which can occasionally cause regressions
    - Any new stateful paths (dotfiles, data dirs) must be explicitly added to impermanence config or they vanish on reboot
  '';

  tuiJson = (pkgs.formats.json {}).generate "tui.json" {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "catppuccin";
  };

  skillImpermanence = pkgs.writeText "SKILL.md" ''
    ---
    name: impermanence
    description: How ephemeral root and impermanence work on this NixOS host
    license: MIT
    compatibility: opencode
    metadata:
      audience: nixos-users
      domain: system-administration
    ---

    ## What I do
    - Explain that `/` is tmpfs and wiped on reboot
    - Describe the `/persist` mount and BTRFS subvolume `@persist`
    - Show how to declare persistent paths via `environment.persistence."/persist"`
    - Warn when a new stateful path is missing from persistence config

    ## When to use me
    Use this skill when the user asks about data persistence, where to store config, or why something disappeared after reboot.

    ## Key conventions
    - Any dotfile, data dir, or state must be in `environment.persistence."/persist"` or it vanishes
    - Common paths: `~/.config`, `~/.local/share`, `~/.local/state`, `~/.ssh`
    - The persistence module is defined in `modules/core.nix` and `modules/users/cookiegigi.nix`
    - Always add new persistent paths to the NixOS config, not manually
  '';

  skillNixBasics = pkgs.writeText "SKILL.md" ''
    ---
    name: nix-basics
    description: Core Nix concepts including the Nix language, flakes, and pure functional package management
    license: MIT
    compatibility: opencode
    metadata:
      audience: nix-users
      domain: system-configuration
    ---

    ## What I do
    - Explain Nix language syntax (functions, attrsets, let-in, with, imports)
    - Describe how Nix flakes work (inputs, outputs, nix flake commands)
    - Clarify pure functional evaluation and why it matters
    - Help understand nixpkgs overlays, lib functions, and common patterns

    ## When to use me
    Use this skill when the user asks about Nix fundamentals, language syntax, or how the Nix ecosystem works.

    ## Key conventions
    - Nix files are pure: no side effects during evaluation
    - Flakes lock dependencies in `flake.lock`
    - Use `lib` helpers from `nixpkgs.lib` instead of reinventing logic
    - Prefer `let` bindings over deeply nested expressions
  '';

  skillNixosRebuild = pkgs.writeText "SKILL.md" ''
    ---
    name: nixos-rebuild
    description: How to build, test, and switch NixOS configurations safely
    license: MIT
    compatibility: opencode
    metadata:
      audience: nixos-users
      domain: system-administration
    ---

    ## What I do
    - Explain `nixos-rebuild switch`, `build`, and `test` differences
    - Guide safe rebuild practices (build first, then switch)
    - Help read `nixos-rebuild` output and errors
    - Suggest rollback strategies (`nixos-rebuild switch --rollback`)

    ## When to use me
    Use this skill when the user needs to rebuild NixOS, troubleshoot a failed build, or understand rebuild commands.

    ## Key conventions
    - Always run `nix fmt` before rebuilding if the repo has a formatter
    - Build first: `sudo nixos-rebuild build --flake .#xps`
    - Switch after verifying: `sudo nixos-rebuild switch --flake .#xps`
    - Use `nix flake check` to validate the flake without building
    - Keep generations so you can roll back if something breaks
  '';
in {
  home.packages = [
    pkgs.opencode
    pkgs.nodejs
    pkgs.nil
  ];

  home.file = {
    ".config/opencode/opencode.json".source = opencodeConfig;
    ".config/opencode/AGENTS.md".source = agentsMd;
    ".config/opencode/tui.json".source = tuiJson;
    ".config/opencode/skills/impermanence/SKILL.md".source = skillImpermanence;
    ".config/opencode/skills/nix-basics/SKILL.md".source = skillNixBasics;
    ".config/opencode/skills/nixos-rebuild/SKILL.md".source = skillNixosRebuild;
  };

  home.persistence."/persist" = {
    directories = [
      ".local/share/opencode"
      ".local/state/opencode"
    ];
  };
}
