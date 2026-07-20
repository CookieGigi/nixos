{
  pkgs,
  lib,
  ...
}: let
  baseConfig = import ../opencode/server-config.nix {inherit pkgs;};
  agents = import ../opencode/agents {};
  agentsMd = import ../opencode/agents.md.nix {inherit pkgs;};
  tui = import ../opencode/tui.nix {inherit pkgs;};
  skills = import ../opencode/skills {inherit pkgs;};

  finalConfig = baseConfig.config // {agent = agents;};
  opencodeJson = (pkgs.formats.json {}).generate "opencode.json" finalConfig;

  skillDirs =
    lib.mapAttrs' (name: skillPath: {
      name = "opencode/skills/${name}";
      value = {
        source = skillPath;
        force = true;
      };
    })
    skills;
in {
  home.packages = [
    pkgs.opencode
    pkgs.nodejs
    pkgs.nil
  ];

  xdg.configFile =
    {
      "opencode/opencode.json" = {
        source = opencodeJson;
        force = true;
      };
      "opencode/AGENTS.md" = {
        source = agentsMd.agentsMd;
        force = true;
      };
      "opencode/tui.json" = {
        source = tui.tuiJson;
        force = true;
      };
    }
    // skillDirs;

  home.persistence."/persist" = {
    directories = [
      ".local/share/opencode"
      ".local/state/opencode"
    ];
  };
}
