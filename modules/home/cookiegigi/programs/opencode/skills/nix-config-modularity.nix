{pkgs, ...}: let
  inherit (import ../lib.nix {inherit pkgs;}) mkSkill;
in
  mkSkill "nix-config-modularity" "How to split large Nix configuration files into focused, maintainable modules" ''
    ## What I do
    - Explain when and why to split a monolithic `.nix` file into smaller modules
    - Describe the directory structure and wiring patterns that keep things maintainable
    - Show how submodules return pure data while the entry point handles side effects (home-manager options, system config, etc.)
    - Use the OpenCode module refactor as a concrete, worked example

    ## When to split

    Consider splitting when any of these apply:
    - The file exceeds ~100-150 lines
    - It contains multiple independent concerns (e.g. agents + skills + LSP + themes)
    - Different team members (or future you) frequently edit different parts
    - You want to add new items (agents, services, keys) without touching unrelated code

    ## General pattern

    ### 1. Directory layout

    Replace `programs/foo.nix` with `programs/foo/`:

    ```
    foo/
    ├── default.nix          # Entry point: imports submodules, assembles, wires options
    ├── lib.nix              # Shared helpers used by submodules
    ├── config.nix           # Static / top-level configuration data
    ├── <concern-a>/
    │   ├── default.nix      # Aggregator: merges all files in this dir
    │   ├── item-1.nix       # One logical unit per file
    │   └── item-2.nix
    └── <concern-b>/
        ├── default.nix
        ├── item-1.nix
        └── item-2.nix
    ```

    ### 2. Entry point responsibilities (`default.nix`)

    - Import all submodules
    - Merge their outputs into the final data structure
    - Perform the **one** generation step (e.g. `pkgs.formats.json {}.generate`)
    - Wire home-manager or NixOS options (`xdg.configFile`, `home.packages`, `systemd.services`, etc.)
    - This is the only file that should reference `config`, `lib`, or system-level options

    ### 3. Submodule responsibilities

    - Return a **raw Nix attrset** (pure data, no side effects)
    - Do NOT set home-manager or NixOS options directly
    - Import `lib.nix` for shared helpers if needed
    - Keep files small and single-purpose

    ### 4. The merge pattern

    When the final config needs to combine static keys with dynamic ones:

    ```nix
    # In default.nix
    let
      baseConfig = import ./config.nix {inherit pkgs;};
      agents = import ./agents {};
    in
      baseConfig.config // {agent = agents;}
    ```

    Then pass the merged attrset to the generator:

    ```nix
    finalJson = (pkgs.formats.json {}).generate "config.json" mergedConfig;
    ```

    ### 5. Subdirectory aggregators

    Each subdirectory has a `default.nix` that acts as an index:

    ```nix
    # agents/default.nix
    {...}:
      (import ./explaining.nix {})
      // (import ./configuration.nix {})
      // (import ./git-commit.nix {})
    ```

    ```nix
    # skills/default.nix
    {pkgs, ...}: {
      impermanence = import ./impermanence.nix {inherit pkgs;};
      nix-basics = import ./nix-basics.nix {inherit pkgs;};
    }
    ```

    ### 6. Helpers in `lib.nix`

    Extract repeated boilerplate into a shared helper. Example from the OpenCode module:

    ```nix
    # lib.nix
    {pkgs, ...}: {
      mkSkill = name: description: content:
        pkgs.writeText "SKILL.md"
          ("---\nname: " + name + "\ndescription: " + description + "\n---\n\n" + content);
    }
    ```

    Import it from submodules:

    ```nix
    {pkgs, ...}: let
      inherit (import ../lib.nix {inherit pkgs;}) mkSkill;
    in
      mkSkill "my-skill" "Does a thing" "..."
    ```

    ## Concrete example: OpenCode module

    We applied this pattern to `modules/home/cookiegigi/programs/opencode.nix` (410 lines) → `opencode/` directory.

    **Before:** one monolithic file with agents, skills, AGENTS.md, TUI config, and home-manager wiring all mixed together.

    **After:**
    - `config.nix` — static JSON keys (model, tools, LSP, MCP, formatter)
    - `agents/` — one file per agent (`explaining.nix`, `configuration.nix`, `git-commit.nix`)
    - `skills/` — one file per skill, using `mkSkill` from `lib.nix`
    - `agents.md.nix` / `tui.nix` — standalone content files
    - `default.nix` — merges `config.nix` + `agents/`, generates JSON, wires `xdg.configFile`

    Result: no file exceeds ~35 lines. Adding a new agent = one ~25-line file + one line in `agents/default.nix`.

    ## Adding a new logical unit (generic recipe)

    1. Decide which subdirectory it belongs to (or create one)
    2. Create `<subdir>/<name>.nix` returning pure data
    3. Add it to `<subdir>/default.nix`
    4. If the entry point needs it, import the subdirectory in `default.nix` and wire it into the final assembly
    5. Run `nix fmt` and `nix flake check`

    ## Key conventions
    - One file per logical unit (agent, skill, service, theme, etc.)
    - Submodules return pure attrsets; the entry point handles side effects
    - Use `xdg.configFile` (not `home.file`) for `$XDG_CONFIG_HOME` paths
    - Use `lib.nix` for shared helpers to stay DRY
    - Subdirectory `default.nix` files are indexes — they should be short and obvious
    - Always run `nix fmt` after editing and `nix flake check` before rebuilding
  ''
