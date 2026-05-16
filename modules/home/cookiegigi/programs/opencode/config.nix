{pkgs, ...}: {
  config = {
    model = "opencode-go/kimi-k2.6";
    small_model = "opencode-go/deepseek-v4-flash";
    default_agent = "build";

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
}
