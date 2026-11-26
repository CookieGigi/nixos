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
    HOME=/tmp/quickshell-greeter
    XDG_CACHE_HOME="$HOME/.cache"
    XDG_STATE_HOME="$HOME/.local/state"

    # Everything below runs pre-auth as the unbaptised greeter user in
    # world-writable /tmp: another local uid could pre-plant this
    # directory (or a symlink) and host or replace the files the greeter
    # uses, so require a same-owner dir and fall back to a private one
    # otherwise. The login screen must come up; do not fail here.
    if ! mkdir -p "$HOME" 2>/dev/null || [ -L "$HOME" ] || [ ! -O "$HOME" ]; then
      HOME="$(${pkgs.coreutils}/bin/mktemp -d /tmp/quickshell-greeter.XXXXXX)"
      XDG_CACHE_HOME="$HOME/.cache"
      XDG_STATE_HOME="$HOME/.local/state"
    fi
    chmod 0700 "$HOME"
    export HOME XDG_CACHE_HOME XDG_STATE_HOME
    mkdir -p "$XDG_CACHE_HOME" "$XDG_STATE_HOME"

    # Lifecycle trace for the failing parts of a login screen you can
    # only see before having a session: /tmp is tmpfs, so this log covers
    # the current boot. The fixed name is only used while it is (or can
    # become) greeter-owned, so it cannot be pointed elsewhere through a
    # pre-planted symlink; the fallback copy keeps the log working.
    # The trace itself is not sensitive (compositor logs, no secrets).
    log=/tmp/quickshell-greeter.log
    if [ -e "$log" ] && [ ! -O "$log" ] || [ -L "$log" ]; then
      log="$HOME/greeter-session.log"
    fi
    exec > "$log" 2>&1
    # Caches etc. stay private behind the 0700 HOME; the trace is the
    # one file the user needs to read after logging in.
    chmod 644 "$log" 2>/dev/null || true
    umask 077

    ts() { ${pkgs.coreutils}/bin/date +%T.%3N; }
    echo "$(ts) greeter session starting (HOME $HOME, log $log)"

    term_niri() {
      # Re-entry guarded: greetd TERMs every second until we are gone, and
      # a second trap firing during wait() delayed the exit by seconds.
      [ -n "$niri_gone" ] && exit 0
      niri_gone=1
      trap - TERM INT
      echo "$(ts) stopping niri (pid $niri_pid)"
      kill -TERM "$niri_pid" 2>/dev/null || true
      # niri's graceful shutdown waits out its clients (swaybg here) and
      # took 1.5-3.4s per boot; a kiosk has nothing worth saving, so cap
      # the grace and collect the exit.
      i=0
      while kill -0 "$niri_pid" 2>/dev/null && [ "$i" -lt 3 ]; do
        i=$((i + 1))
        "$sleep_cmd" 0.1
      done
      kill -KILL "$niri_pid" 2>/dev/null || true
      wait "$niri_pid" 2>/dev/null || true
      echo "$(ts) greeter session exiting"
      exit 0
    }
    # Also for greetd's own SIGTERM (e.g. on shutdown) and the Ctrl+C case.
    trap term_niri TERM INT

    # Defined before any code that could fire the trap needs them.
    pgrep="${pkgs.procps}/bin/pgrep"
    sleep_cmd="${pkgs.coreutils}/bin/sleep"
    cut_cmd="${pkgs.coreutils}/bin/cut"
    uid="$(${pkgs.coreutils}/bin/id -u)"

    ${lib.getExe config.programs.niri.package} -c ${kioskConfig} &
    niri_pid=$!
    echo "$(ts) niri started (pid $niri_pid)"
    echo "$(ts) greeter uid $uid"

    # niri double-forks spawned commands, so quickshell is not a child of
    # this shell: watch for it by process name + uid instead. The nixpkgs
    # quickshell package wraps its binaries, so the greeter process comm
    # is ".quickshell-wrapped" (truncated to 15 chars: ".quickshell-wra"),
    # not "qs"/"quickshell": match unanchored so both the wrapped and the
    # plain binary name work.
    qs_pid=""
    waited=0
    while [ -z "$qs_pid" ] && [ "$waited" -lt 300 ]; do
      qs_pid="$("$pgrep" -u "$uid" 'quickshell' | ${pkgs.coreutils}/bin/head -n 1 || true)"
      waited=$((waited + 1))
      [ -n "$qs_pid" ] || "$sleep_cmd" 0.1
    done
    if [ -n "$qs_pid" ]; then
      echo "$(ts) quickshell pid $qs_pid comm $(< /proc/$qs_pid/comm)"
    else
      echo "$(ts) quickshell not found after $waited polls"
    fi

    if [ -n "$qs_pid" ]; then
      # Poll until quickshell is gone (~100 ms): on success it exits the
      # moment greetd acknowledges the session launch. Killed processes
      # cannot be detected with kill -0 alone: this shell is a subreaper
      # (the greetd session worker sets PR_SET_CHILD_SUBREAPER), so
      # quickshell stays around as a zombie child until reaped. Watch the
      # process state instead.
      while :; do
        state="$("$cut_cmd" -d ' ' -f 3 /proc/$qs_pid/stat 2>/dev/null)" || break
        [ "$state" = "Z" ] && break
        "$sleep_cmd" 0.1
      done
      wait "$qs_pid" 2>/dev/null || true
      echo "$(ts) quickshell gone (state was $state)"
    fi

    # If quickshell never started or crashed, give up on this greeter
    # instance too: the session exits and greetd restarts the greeter.
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
