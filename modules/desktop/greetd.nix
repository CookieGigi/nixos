{
  config,
  lib,
  pkgs,
  ...
}: let
  # Greeter QML config built by home-manager the same way as the lockscreen
  # derivation. Referencing the store path here keeps it reachable from the
  # greetd systemd unit even for the greeter user.
  # The user can also dry-run it in-session with `qs -c greeter`.
  greeterConfig = config.home-manager.users.cookiegigi.xdg.configFile."quickshell/greeter".source;

  # Kiosk niri config with store paths substituted in
  # (repo template kept for the niri-validate pre-commit hook).
  kioskConfig = pkgs.runCommand "niri-greeter-kiosk.kdl" {} ''
    cp ${./greetd/niri-greeter.kdl} $out
    substituteInPlace $out \
      --replace-fail '"@qs@"' '"${lib.getExe pkgs.quickshell}"' \
      --replace-fail '"@greeterConfig@"' '"${greeterConfig}"'
  '';

  # Wrapper run by greetd as the greeter user on tty1.
  # The greeter user has no real home, so it gets an ephemeral one in /tmp
  # (shader caches and quickshell state; root is a tmpfs anyway).
  greeterSession = pkgs.writeShellScript "greetd-quickshell-greeter" ''
    export HOME=/tmp/quickshell-greeter
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_STATE_HOME="$HOME/.local/state"
    mkdir -p "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
    exec ${lib.getExe config.programs.niri.package} -c ${kioskConfig}
  '';
in {
  # greetd replaces SDDM. The NixOS module creates the system `greeter`
  # user/group, pins the greeter to tty1, wires PAM + the
  # display-manager.service alias, and restarts the greeter on crash.
  services.greetd = {
    enable = true;
    settings.default_session.command = "${greeterSession}";
  };
}
