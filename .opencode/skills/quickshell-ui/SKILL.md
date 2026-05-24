# Quickshell UI Skill

Skill for building rich desktop shells (bars, dashboards, launchers, OSDs) using Quickshell on Wayland compositors like **niri**, based on patterns distilled from the `caelestia-dots/shell` reference implementation.

> **Note:** The original `caelestia-dots/shell` is deeply tied to Hyprland. This skill extracts the generic Quickshell patterns and adapts them for compositors that do not have Quickshell's native Hyprland integration module.

---

## 1. What is Quickshell

Quickshell is a framework for building Wayland desktop shells in Qt6/QML. It replaces traditional widget/GTK bars (like waybar) with declarative QML that renders directly as Wayland surfaces.

Key capabilities:
- Wayland Layer Shell (`zwlr_layer_shell_v1`) for bars, overlays, notifications
- `IpcHandler` for exposing internal functions to CLI/external tools
- Per-monitor instantiation via `Variants { model: Screens.screens }`
- Hot-reload in development via `settings.watchFiles: true`
- Works on any compositor supporting `wlr-layer-shell` and `xdg-shell` (niri, sway, dwl, etc.)

**What you lose without Hyprland:**
- `Quickshell.Hyprland` module (live workspace/window/monitor objects)
- `CustomShortcut` D-Bus global shortcuts (Hyprland-specific protocol)
- `HyprlandFocusGrab` (compositor-specific focus grab)

**What you keep:**
- All layer-shell window positioning
- All QML rendering, animations, and styling
- `IpcHandler` for external control
- Pipewire, NetworkManager, and other service integrations
- Per-monitor multi-window support

---

## 2. Recommended Project Structure

```
my-shell/
  shell.qml                 # Entry point, must be at repo root for qs -c
  CMakeLists.txt            # Optional; for C++ plugins / install target
  components/               # Reusable QML components (buttons, icons, rects)
  modules/                  # Top-level UI modules (bar, dashboard, launcher)
  modules/bar/
  modules/dashboard/
  services/                 # Singletons for system state (audio, network, time)
  utils/                    # Helper QML / JS files
  assets/                   # Images, fonts, etc.
```

> Install the shell into `$XDG_CONFIG_HOME/quickshell/<name>` so Quickshell can find it via `qs -c <name>`.

---

## 3. Entry Point (`shell.qml`)

Use `ShellRoot` and set pragmas for tuning:

```qml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
import Quickshell

ShellRoot {
    settings.watchFiles: true   // enable in dev only

    BarModule {}
    DashboardModule {}
    LauncherModule {}
    NotificationsModule {}

    NiriState {}               // your compositor state tracker (optional)
    ConfigLoader {}            // your settings singleton
}
```

For production builds, strip `settings.watchFiles: true` (CMake string-replace is a clean way).

---

## 4. Wayland Layer Shell Windows

Every surface needs a `WlrLayershell` configuration. Use `StyledWindow` or `PanelWindow` from Quickshell.

```qml
import Quickshell
import Quickshell.Wayland

StyledWindow {
    name: "drawers"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
}
```

Common `WlrLayer` choices:
- `Background` — wallpaper/visualizer
- `Bottom` — desktop widgets behind windows
- `Top` — bars, docks
- `Overlay` — lock screen, fullscreen overlays, modal launchers

`keyboardFocus` should be `OnDemand` when a launcher/session dialog is open, and `None` otherwise.

---

## 5. Compositor State Without Native Integration

Since `Quickshell.Hyprland` is unavailable on niri, you must track compositor state manually via IPC or D-Bus.

### 5.1 niri IPC

niri exposes a control socket and a `niri msg` CLI. Read events from the socket or poll state via commands.

```qml
// services/NiriState.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var workspaces: []
    property var windows: []
    property string focusedOutput: ""
    property string focusedWorkspace: ""

    function refreshState(): void {
        niriProcess.running = true;
    }

    function dispatch(msg: string): void {
        dispatchProcess.command = ["niri", "msg", "action", msg];
        dispatchProcess.running = true;
    }

    Process {
        id: niriProcess
        command: ["niri", "msg", "--json", "windows"]
        onExited: {
            if (stdout.trim()) {
                try {
                    const data = JSON.parse(stdout);
                    root.windows = data;
                } catch (e) {
                    console.warn("Failed to parse niri msg output:", e);
                }
            }
        }
    }

    Process {
        id: dispatchProcess
        command: []
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: root.refreshState()
    }
}
```

For real-time event streaming, listen to niri's event socket (where available) or parse `niri msg` outputs. Adjust polling intervals to balance responsiveness vs. CPU usage.

### 5.2 Generic approach for any compositor

Use `Quickshell.Io.Process` to run compositor CLI commands and parse JSON output. Cache results in singleton properties. Use `Timer` for polling where event sockets are not available.

---

## 6. Keybind Architecture (niri-compatible)

On niri, `CustomShortcut` (Hyprland global shortcuts over D-Bus) **does not work**. Use one of these strategies instead:

### 6.1 niri config binds + Quickshell IPC (Recommended)

Define shortcuts in `~/.config/niri/config.kdl` that spawn `qs -c <name> ipc <target> <function>`:

```kdl
// niri config.kdl
binds {
    Mod+"R" { spawn "qs" "-c" "myshell" "ipc" "drawers" "toggle" "launcher"; }
    Mod+"D" { spawn "qs" "-c" "myshell" "ipc" "drawers" "toggle" "dashboard"; }
    Mod+"Escape" { spawn "qs" "-c" "myshell" "ipc" "drawers" "toggle" "session"; }
}
```

In your QML, expose the target via `IpcHandler`:

```qml
// modules/Shortcuts.qml
import Quickshell

Scope {
    IpcHandler {
        function toggle(drawer: string): void {
            const valid = ["launcher", "dashboard", "session", "sidebar"];
            if (!valid.includes(drawer)) {
                console.warn("Unknown drawer:", drawer);
                return;
            }
            const v = Visibilities.getForActive();
            if (!v) return;
            v[drawer] = !v[drawer];
        }

        target: "drawers"
    }
}
```

> This is the cleanest separation: niri owns the key combinations; the shell owns the behavior.

### 6.2 Local `Keys.onPressed` (for focused UI only)

When a drawer/launcher has keyboard focus (`WlrKeyboardFocus.OnDemand`), you can handle keys inside that window:

```qml
import QtQuick

Item {
    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            visibilities.launcher = false;
            event.accepted = true;
        }
    }
}
```

Use this for **in-UI navigation** (Escape to close, arrow keys, Enter to select) but **not** for global shortcuts.

### 6.3 Press-and-hold pattern (if using a key daemon)

If you use a separate keybinding daemon (e.g. `swayosd`, `ydotool`, or a custom listener) that can send press/release events over IPC, you can replicate the Super-key dual-use pattern:

1. On press: set a flag
2. On interrupt (another key pressed while held): set an interrupt flag
3. On release: only toggle if not interrupted

With pure niri binds, this is not possible because niri only fires on press, not release. You would need a daemon that tracks key state.

### 6.4 Fullscreen guard

Without Hyprland's `lastIpcObject.fullscreen`, detect fullscreen by:
- Parsing `niri msg --json windows` and checking window states
- Or querying your compositor's window state via its IPC

```qml
readonly property bool hasFullscreen: {
    // Example: check if any window on focused output is fullscreen
    NiriState.windows.some(w => w.is_focused && w.is_fullscreen) ?? false
}
```

---

## 7. State Management: The Visibilities Pattern

Rather than local `visible` properties, use a **per-monitor visibility singleton** that all modules bind to.

```qml
// services/Visibilities.qml
pragma Singleton
import Quickshell

Singleton {
    property var screens: new Map()   // ShellScreen -> DrawerVisibilities
    property var bars: new Map()      // ShellScreen -> Bar

    function load(screen: ShellScreen, visibilities: DrawerVisibilities): void {
        screens.set(screen, visibilities);
    }

    function getForActive(): DrawerVisibilities {
        // On niri, pick the screen containing the cursor or the first screen
        const primary = Screens.screens.find(s => s.primary) ?? Screens.screens[0];
        return screens.get(primary);
    }
}
```

```qml
// components/DrawerVisibilities.qml
import QtQuick

QtObject {
    property bool launcher: false
    property bool dashboard: false
    property bool session: false
    property bool sidebar: false
    property bool osd: false
    property bool utilities: false
}
```

Each monitor's `ContentWindow` creates its own `DrawerVisibilities` instance and registers it. Shortcuts then call `Visibilities.getForActive()` to toggle only the focused monitor's drawers.

---

## 8. IPC for External Control

Use `IpcHandler` to let external scripts / CLI / niri keybinds control the shell.

```qml
IpcHandler {
    function toggle(drawer: string): void {
        const list = ["launcher", "dashboard", "session", "sidebar"];
        if (!list.includes(drawer)) return;
        const v = Visibilities.getForActive();
        v[drawer] = !v[drawer];
    }

    function list(): string {
        return "launcher\ndashboard\nsession\nsidebar";
    }

    target: "drawers"
}
```

Access from shell:
```bash
qs -c myshell ipc drawers toggle launcher
```

This is how niri keybinds communicate with the shell.

---

## 9. Multi-Monitor Support

Use `Variants` to instantiate one window/controller per monitor:

```qml
// modules/Drawers.qml
import Quickshell

Variants {
    model: Screens.screens

    Scope {
        id: scope
        required property ShellScreen modelData

        ContentWindow {
            screen: scope.modelData
        }
    }
}
```

Inside `ContentWindow`, reference `screen` to get geometry. Use `screen.name` or `screen.physicalGeometry` for positioning.

---

## 10. Visual Patterns

### 10.1 SDF Blob Backgrounds (caelestia style)
Use a `BlobGroup` + `BlobInvertedRect` (custom C++ QML types) to create organic, deformable backgrounds that react to panel positions. If you don't have the C++ plugin, approximate with:
- `MultiEffect` (shadow + blur)
- `Rectangle` with `radius`
- `QtQuick.Effects` layer effects

### 10.2 Animations
Use a shared `Anim.qml` component with consistent easing and duration tokens:

```qml
// components/Anim.qml
import QtQuick

Behavior {
    NumberAnimation {
        duration: 300
        easing.type: Easing.InOutCubic
    }
}
```

Bind to `fsTransitionProg` (fullscreen transition progress) to morph bar/panel geometry between normal and fullscreen modes.

### 10.3 Focus Grab
When a modal drawer opens, you want keyboard focus to stay inside the drawer and auto-close on outside click.

Without `HyprlandFocusGrab`, implement this manually:

```qml
// In your launcher/session window
WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

// Close on Escape via Keys.onPressed (see section 6.2)
// Close on outside click via a full-screen transparent mouse area behind the panel

MouseArea {
    anchors.fill: parent
    z: -1
    onClicked: {
        visibilities.launcher = false;
        visibilities.session = false;
    }
}
```

Note: `HyprlandFocusGrab` is a Hyprland-specific Quickshell feature. On generic compositors, rely on `WlrKeyboardFocus.OnDemand` and manual dismissal.

---

## 11. Build & Install

For a pure-QML shell, no build is needed; clone to `~/.config/quickshell/myshell` and run `qs -c myshell`.

If you have a C++ plugin, use CMake:

```cmake
cmake_minimum_required(VERSION 3.19)
project(my-shell LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)

# plugin
add_subdirectory(plugin)

# install QML files
foreach(dir assets components modules services)
    install(DIRECTORY ${dir} DESTINATION "etc/xdg/quickshell/myshell")
endforeach()
install(FILES shell.qml DESTINATION "etc/xdg/quickshell/myshell")
```

> The Quickshell config search path includes `/etc/xdg/quickshell/<name>` and `~/.config/quickshell/<name>`.

---

## 12. Pitfalls to Avoid

| Anti-pattern | Correct approach |
|---|---|
| Expecting `CustomShortcut` to work on niri | Use niri config binds that spawn `qs -c <name> ipc ...` |
| Storing `visible` in local window properties | Use a per-monitor singleton (`Visibilities`) |
| Polling compositor state too aggressively | Use event sockets where available; otherwise 250-500ms timers |
| Opening UI over fullscreen windows | Parse compositor window state and guard toggles |
| Single global bar instance | Use `Variants { model: Screens.screens }` per monitor |
| Hard-coding key combos in QML | Keep key combos in compositor config; shell only exposes named IPC targets |
| Blocking the render thread with heavy JS | Offload to C++ plugin or use `WorkerScript` |
| Assuming `HyprlandFocusGrab` exists | Use `WlrKeyboardFocus.OnDemand` + manual dismissal |

---

## 13. Quick Start Template (niri-compatible)

```qml
// shell.qml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
import Quickshell
import "modules"

ShellRoot {
    settings.watchFiles: true
    Bar {}
}
```

```qml
// modules/Bar.qml
import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    model: Screens.screens
    Scope {
        required property ShellScreen modelData
        PanelWindow {
            screen: modelData
            anchors.top: true
            anchors.left: true
            anchors.right: true
            height: 40
            color: "#1e1e2e"

            Text {
                anchors.centerIn: parent
                text: Qt.formatDateTime(new Date(), "hh:mm")
                color: "#cdd6f4"
            }
        }
    }
}
```

niri config (`~/.config/niri/config.kdl`):
```kdl
binds {
    // If you want a keybind to toggle something, spawn qs ipc:
    // Mod+"R" { spawn "qs" "-c" "myshell" "ipc" "drawers" "toggle" "launcher"; }
}
```

Run:
```bash
mkdir -p ~/.config/quickshell
ln -s /path/to/repo ~/.config/quickshell/myshell
qs -c myshell
```

---

## 14. Further Reading

- Quickshell docs: https://quickshell.outfoxxed.me
- Reference implementation (Hyprland-specific): https://github.com/caelestia-dots/shell
- niri wiki / config docs: https://github.com/YaLTeR/niri
- Wayland layer shell protocol: https://wayland.app/protocols/wlr-layer-shell-unstable-v1
