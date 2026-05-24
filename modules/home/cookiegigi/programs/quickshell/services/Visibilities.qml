pragma Singleton
import Quickshell
import QtQuick

// Per-monitor drawer state singleton.
// Each Bar instance registers its screen on completion.
// IPC handlers use getForActive() to toggle the focused monitor's drawers.
Singleton {
    id: root

    property var states: new Map()   // ShellScreen -> VisibilitiesState

    function register(screen, stateObj) {
        states.set(screen, stateObj);
    }

    function getForActive() {
        // Prefer primary screen, fallback to first
        const primary = Quickshell.screens.find(s => s.primary) ?? Quickshell.screens[0];
        return states.get(primary) ?? null;
    }

    function getForScreen(screen) {
        return states.get(screen) ?? null;
    }

    function toggleLauncher(screen) {
        const v = states.get(screen);
        if (v) v.launcher = !v.launcher;
    }

    function togglePower(screen) {
        const v = states.get(screen);
        if (v) v.power = !v.power;
    }
}
