# Analysis: caelestia-dots/shell

## Overview

**caelestia-shell** is a full-featured desktop shell for **Hyprland** (Wayland) built on top of **Quickshell** — a framework that lets you write Wayland shells in Qt6/QML. It replaces waybar and provides a unified experience including: a status bar, dashboard, launcher, notification center, OSD, session menu, lock screen, audio visualizer, and various pop-out panels.

Repository composition: ~75% QML, ~19% C++, with a CMake build system and Nix packaging.

---

## How Quickshell is Used

Quickshell is the **entire runtime foundation**. The shell *is* a Quickshell configuration.

### 1. Entry Point & Root Architecture
The entry point is `shell.qml`, which starts with Quickshell pragmas and imports:

```qml
//@ pragma Env QS_CRASHREPORT_URL=...
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
import Quickshell

ShellRoot {
    settings.watchFiles: true
    Background {}
    Drawers {}
    AreaPicker {}
    Lock { id: lock }
    ConfigToasts {}
    Shortcuts {}
    BatteryMonitor {}
    IdleMonitors { lock: lock }
}
```

- `ShellRoot` is the Quickshell root element.
- `settings.watchFiles: true` enables hot-reloading during development.

### 2. Wayland Layer Shell (`WlrLayershell`)
Every major UI surface is a Quickshell `StyledWindow` decorated with `WlrLayershell` properties to place windows on Wayland layers:

```qml
StyledWindow {
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: fsTransitionProg > 0 && contentItem.Config.general.showOverFullscreen
                         ? WlrLayer.Overlay
                         : WlrLayer.Top
    WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.session
                                 ? WlrKeyboardFocus.OnDemand
                                 : WlrKeyboardFocus.None
    anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
}
```

This is how the bar, drawers, notifications, and OSD reserve screen space and handle input focus correctly on Wayland.

### 3. Hyprland Deep Integration (`Quickshell.Hyprland`)
The shell has **deep real-time integration** with Hyprland via Quickshell's Hyprland module:

- `Hyprland.toplevels` / `.workspaces` / `.monitors` — live objects tracking window state.
- `Hyprland.focusedWorkspace` / `focusedMonitor` — reactive focus tracking.
- `Hyprland.dispatch(...)` — sends IPC commands back to Hyprland.
- `HyprlandFocusGrab` — steals keyboard focus when launcher/session is open.
- `HyprExtras` — extended device/option querying.

Example from `services/Hypr.qml`:
```qml
readonly property HyprlandToplevel activeToplevel: { ... }
readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
function dispatch(request: string): void { Hyprland.dispatch(request); }
```

### 4. Screen Per-Monitor Instantiation
Quickshell's `Variants` component spawns per-monitor instances dynamically:

```qml
Variants {
    model: Screens.screens
    Scope {
        required property ShellScreen modelData
        ContentWindow { screen: scope.modelData }
    }
}
```

Each monitor gets its own `ContentWindow`, bar, and drawer state.

### 5. IPC (`IpcHandler`)
Quickshell provides `IpcHandler` for exposing internal functions to external processes. This powers the `caelestia shell ...` CLI:

```qml
IpcHandler {
    function toggle(drawer: string): void { ... }
    function list(): string { ... }
    target: "drawers"
}

IpcHandler {
    function refreshDevices(): void { ... }
    target: "hypr"
}
```

From the terminal you can run `caelestia shell drawers toggle launcher` or `caelestia shell mpris playPause`.

### 6. Services as QML Singletons
System state is managed via QML `Singleton` objects in the `services/` directory:

| Service | Role |
|---|---|
| `Audio.qml` | Pipewire audio via `Quickshell.Services.Pipewire` |
| `Brightness.qml` | Backlight/DDDC brightness control |
| `Network.qml` / `Nmcli.qml` | NetworkManager state |
| `Hypr.qml` | Hyprland workspaces, windows, monitors |
| `Screens.qml` | Screen geometry |
| `Visibilities.qml` | Per-monitor drawer visibility state |
| `SystemUsage.qml` | CPU/RAM/GPU usage |
| `Weather.qml` | Weather fetching |
| `VPN.qml` | VPN state |

These use Quickshell's `Process`, `FileView`, and Qt `Connections` to poll or react to system changes.

### 7. Custom C++ Plugin (`plugin/`)
There is a native C++ plugin providing custom QML types like:
- `Caelestia.Blobs` (SDF blob background effects)
- `Caelestia.Config` (configuration loader)
- `Caelestia.Services` (`CavaProvider`, `BeatTracker`)
- `Caelestia.Internal`

This is registered as a standard Qt6 QML plugin and imported throughout.

---

## How Keybinds Are Handled

Keybinds are **not** handled via local QML `Keys.onPressed` events. Instead, they use **Hyprland Global Shortcuts** through Quickshell's `CustomShortcut` type, which registers shortcuts over D-Bus.

### 1. The `CustomShortcut` QML Type
From `modules/Shortcuts.qml`:

```qml
CustomShortcut {
    name: "launcher"
    description: "Toggle launcher"
    onPressed: root.launcherInterrupted = false
    onReleased: {
        if (!root.launcherInterrupted && !root.hasFullscreen) {
            const visibilities = Visibilities.getForActive();
            visibilities.launcher = !visibilities.launcher;
        }
        root.launcherInterrupted = false;
    }
}

CustomShortcut {
    name: "launcherInterrupt"
    description: "Interrupt launcher keybind"
    onPressed: root.launcherInterrupted = true
}
```

And from `services/Hypr.qml`:
```qml
CustomShortcut {
    name: "refreshDevices"
    description: "Reload devices"
    onPressed: extras.refreshDevices()
    onReleased: extras.refreshDevices()
}
```

### 2. Hyprland Configuration Side
The actual key **combinations** are **not** defined in this repo. They are defined in the companion Hyprland configuration (in the `caelestia-dots/caelestia` repo) using Hyprland's global shortcut syntax:

```conf
bind = , KEY, global, caelestia:NAME
```

For example:
```conf
bind = SUPER, R, global, caelestia:launcher
bind = SUPER, D, global, caelestia:dashboard
bind = SUPER, Escape, global, caelestia:session
bind = SUPER, C, global, caelestia:controlCenter
bind = SUPER, S, global, caelestia:showall
```

The README states: *"All keybinds are accessible via Hyprland global shortcuts"*.

### 3. What Shortcuts Do
Rather than executing shell commands, shortcuts **toggle visibility states** stored in the `Visibilities` singleton, which is a per-monitor map:

```qml
onPressed: {
    if (root.hasFullscreen) return; // blocked on fullscreen
    const visibilities = Visibilities.getForActive();
    visibilities.dashboard = !visibilities.dashboard;
}
```

The `ContentWindow` and `Interactions` modules bind to these booleans to animate drawers in/out.

### 4. Special Behaviors
- **Launcher interrupt**: The launcher uses a press-and-hold pattern. If you hold the launcher key and press another key (the `launcherInterrupt` shortcut), the launcher does not open on release. This allows using the Super key both as a modifier and as a launcher trigger.
- **Fullscreen guard**: Most shortcuts check `root.hasFullscreen` and return early, preventing UI from opening over fullscreen games/videos.
- **Focus grab**: When a drawer opens, `HyprlandFocusGrab` is activated to capture keyboard input, and `onCleared` resets all visibility states when focus is lost.

### 5. Programmatic Access (IPC)
Shortcuts also have programmatic equivalents via `IpcHandler`:

```qml
IpcHandler {
    function toggle(drawer: string): void {
        const visibilities = Visibilities.getForActive();
        visibilities[drawer] = !visibilities[drawer];
    }
    target: "drawers"
}
```

This means `caelestia shell drawers toggle launcher` does the same thing as pressing the configured keybind.

---

## Summary

| Aspect | Implementation |
|---|---|
| **Framework** | Quickshell (Qt6/QML Wayland shell framework) |
| **Compositor target** | Hyprland only |
| **Window model** | `WlrLayershell` anchored windows per monitor |
| **State management** | QML Singletons (`Visibilities`, `Hypr`, `Audio`, etc.) |
| **Keybind mechanism** | `CustomShortcut` -> Hyprland Global Shortcuts (D-Bus) |
| **Key definitions** | In Hyprland config (`caelestia:NAME` targets) |
| **IPC / CLI** | `IpcHandler` QML types, consumed via `caelestia shell ...` |
| **Native code** | C++ plugin for config, audio analysis, blob SDF rendering |
| **Build** | CMake + Ninja; installs QML to Quickshell config dir |

In short, this is a **sophisticated Quickshell-native shell** that leverages Quickshell's Hyprland and Wayland integration to the fullest, with keybinds entirely delegated to Hyprland's global shortcut system via D-Bus rather than being handled internally.
