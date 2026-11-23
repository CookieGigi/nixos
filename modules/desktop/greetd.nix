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
      --replace-fail '"@greeterConfig@"' '"${greeterConfig}"' \
      --replace-fail '"@swaybg@"' '"${lib.getExe pkgs.swaybg}"' \
      --replace-fail '"@wallpaper@"' '"${greeterConfig}/wallpaper.jpg"'
  '';

  # Wrapper run by greetd as the greeter user on tty1.
  # The greeter user has no real home, so it gets an ephemeral one in /tmp
  # (shader caches and quickshell state; root is a tmpfs anyway).
  #
  # The wrapper keeps the greeter "well-behaved": quickshell exits right
  # after greetd acknowledges the session launch (Greetd.launch()), but
  # niri alone has no reason to exit once its only client is gone — and
  # greetd then waits ~5 seconds before even SIGTERMing the greeter (then
  # once per second). That grace period is the long gray screen after
  # confirming the login. Instead, this wrapper stops niri and exits as
  # soon as quickshell disappears, so greetd can hand the tty over to the
  # user session right away. It also covers quickshell crashing: the
  # greeter session ends and greetd restarts it, instead of leaving an
  # interactive-less kiosk compositing a login screen nobody can type on.
  greeterSession = pkgs.writeShellScript "greetd-quickshell-greeter" ''
    export HOME=/tmp/quickshell-greeter
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_STATE_HOME="$HOME/.local/state"
    mkdir -p "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

    term_niri() {
      kill -TERM "$niri_pid" 2>/dev/null || true
      wait "$niri_pid" 2>/dev/null || true
      exit 0
    }
    # Also for greetd's own SIGTERM (e.g. on shutdown) and the Ctrl+C case.
    trap term_niri TERM INT

    ${lib.getExe config.programs.niri.package} -c ${kioskConfig} &
    niri_pid=$!

    pgrep="${pkgs.procps}/bin/pgrep"
    sleep_cmd="${pkgs.coreutils}/bin/sleep"
    uid="$(${pkgs.coreutils}/bin/id -u)"

    # niri double-forks spawned commands, so quickshell is not a child of
    # this shell: watch for it by process name + uid instead.
    qs_pid=""
    waited=0
    while [ -z "$qs_pid" ] && [ "$waited" -lt 300 ]; do
      qs_pid="$("$pgrep" -u "$uid" -x qs | ${pkgs.coreutils}/bin/head -n 1 || true)"
      waited=$((waited + 1))
      [ -n "$qs_pid" ] || "$sleep_cmd" 0.1
    done

    if [ -n "$qs_pid" ]; then
      # Poll until quickshell is gone (~100 ms granularity): on success it
      # exits the moment greetd acknowledges the session launch.
      while kill -0 "$qs_pid" 2>/dev/null; do
        "$sleep_cmd" 0.1
      done
    fi

    # If quickshell never started (bad config, crash at startup) give up on
    # this greeter instance too: greetd restarts the service.
    term_niri
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
