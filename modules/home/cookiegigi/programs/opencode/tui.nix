{pkgs, ...}: {
  tuiJson = (pkgs.formats.json {}).generate "tui.json" {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "catppuccin";
  };
}
