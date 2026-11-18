{
  pkgs,
  lib,
  config,
  ...
}: let
  background = config.cookiegigi.theme.backgroundColor;
  source = pkgs.lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      (pkgs.lib.hasSuffix ".qml" path && !pkgs.lib.hasInfix "/lockscreen/" path)
      || type == "directory";
  };
  configuredSource = pkgs.runCommand "quickshell-config" {} ''
    mkdir -p $out
    cp -r ${source}/. $out/
    chmod -R u+w $out
    substituteInPlace $out/theme/Theme.qml \
      --replace-fail '"@themeBackground@"' '"${background}"'
  '';
in {
  home.packages = with pkgs; [
    quickshell
    (import ./prayer-times-json.nix {inherit pkgs lib;})
  ];

  # Symlink quickshell QML config into ~/.config/quickshell/bar/
  # so it can be launched with `qs -c bar`.
  xdg.configFile."quickshell/bar" = {
    source = configuredSource;
    recursive = true;
  };

  # Lockscreen config with full quickshell modules/widgets available,
  # launched with `qs -c lockscreen`.
  xdg.configFile."quickshell/lockscreen" = {
    source = pkgs.runCommand "quickshell-lockscreen" {} ''
      mkdir -p $out/pam
      cp -r ${configuredSource}/* $out/
      chmod -R u+w $out
      cp ${./lockscreen/shell.qml} $out/shell.qml
      cp ${./lockscreen/LockContext.qml} $out/LockContext.qml
      cp ${./lockscreen/LockSurface.qml} $out/LockSurface.qml
      cp ${./lockscreen/LockBar.qml} $out/LockBar.qml
      cp ${./lockscreen/pam/password.conf} $out/pam/password.conf
    '';
    recursive = true;
  };
}
