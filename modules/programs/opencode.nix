{
  pkgs,
  lib,
  ...
}: let
  opencodeConfig = (pkgs.formats.json {}).generate "opencode.json" {
    agent = {
      explaining = {
        model = "opencode-go/kimi-k2.6";
        mode = "subagent";
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
        mode = "subagent";
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
in {
  environment.systemPackages = [
    pkgs.opencode
    pkgs.nodejs
    pkgs.nil
  ];

  # Seed the global config file only if it does not already exist.
  # Because ~/.config/opencode is persisted, this is usually a no-op
  # after the first boot. The user can edit the file later.
  # Note: opencode reads the global config as opencode.json (not .opencode.json).
  system.activationScripts.opencode-config = ''
    mkdir -p /home/cookiegigi/.config/opencode
    if [ ! -f /home/cookiegigi/.config/opencode/opencode.json ]; then
      cp ${opencodeConfig} /home/cookiegigi/.config/opencode/opencode.json
      chown cookiegigi:users /home/cookiegigi/.config/opencode/opencode.json
      chmod 644 /home/cookiegigi/.config/opencode/opencode.json
    fi
    # Clean up legacy filename if it exists
    if [ -f /home/cookiegigi/.config/opencode/.opencode.json ]; then
      rm -f /home/cookiegigi/.config/opencode/.opencode.json
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
