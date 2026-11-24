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
      (pkgs.lib.hasSuffix ".qml" path && !pkgs.lib.hasInfix "/lockscreen/" path && !pkgs.lib.hasInfix "/greeter/" path && !pkgs.lib.hasInfix "/splash/" path)
      || type == "directory";
  };
  configuredSource = pkgs.runCommand "quickshell-config" {} ''
    mkdir -p $out
    cp -r ${source}/. $out/
    chmod -R u+w $out
    substituteInPlace $out/theme/Theme.qml \
      --replace-fail 'readonly property color base: "#0d1117"' 'readonly property color base: "${background}"'
  '';
in {
  home.packages = with pkgs; [
    quickshell
    brightnessctl
    (import ./prayer-times-json.nix {inherit pkgs lib;})
  ];

  xdg.configFile = {
    # Symlink quickshell QML config into ~/.config/quickshell/bar/
    # so it can be launched with `qs -c bar`.
    "quickshell/bar" = {
      source = configuredSource;
      recursive = true;
    };

    # Lockscreen config with full quickshell modules/widgets available,
    # launched with `qs -n -c lockscreen`.
    "quickshell/lockscreen" = {
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

    # Greetd greeter config: the lockscreen look as a login screen,
    # running under the greeter user via greetd (see modules/desktop/greetd.nix).
    # Store paths and the username prefill are substituted so the greeter
    # user needs no XDG dirs, PATH, or access to the home directory.
    # The wallpaper is bundled so the greeter user can read it.
    # Also symlinked for the user, enabling a dry run with `qs -c greeter`
    # (Greetd.available will be false inside the session).
    "quickshell/greeter" = {
      source = pkgs.runCommand "quickshell-greeter" {} ''
        mkdir -p $out
        cp -r ${configuredSource}/* $out/
        chmod -R u+w $out
        cp ${./greeter/shell.qml} $out/shell.qml
        cp ${./greeter/GreeterContext.qml} $out/GreeterContext.qml
        cp ${./greeter/GreeterSurface.qml} $out/GreeterSurface.qml
        cp ${../../wallpapers/voyager-4.jpg} $out/wallpaper.jpg
        substituteInPlace $out/GreeterContext.qml \
          --replace-fail '"@niriSession@"' '"${pkgs.niri}/bin/niri-session"' \
          --replace-fail '"@defaultUser@"' '"${config.home.username}"'
      '';
      recursive = true;
    };
    # Session-opening splash: wallpaper + spinner over the session while
    # the bar loads, dismissed by the bar over IPC once it is up (see the
    # splashDismiss Process in shell.qml). Spawned by niri at session
    # startup with `qs -c splash` (see the niri config.kdl).
    "quickshell/splash" = {
      source = pkgs.runCommand "quickshell-splash" {} ''
        mkdir -p $out
        cp -r ${configuredSource}/* $out/
        chmod -R u+w $out
        cp ${./splash/shell.qml} $out/shell.qml
        cp ${../../wallpapers/voyager-4.jpg} $out/wallpaper.jpg
      '';
      recursive = true;
    };
  };
}
