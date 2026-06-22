{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    quickshell
    (import ./prayer-times-json.nix {inherit pkgs lib;})
  ];

  # Symlink quickshell QML config into ~/.config/quickshell/bar/
  # so it can be launched with `qs -c bar`.
  xdg.configFile."quickshell/bar" = {
    source = pkgs.lib.cleanSourceWith {
      src = ./.;
      filter = path: type:
        pkgs.lib.hasSuffix ".qml" path
        || type == "directory";
    };
    recursive = true;
  };
}
