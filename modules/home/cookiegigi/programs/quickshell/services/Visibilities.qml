pragma Singleton
import Quickshell
import QtQuick

// Per-monitor drawer state singleton.
// Each Bar instance registers its screen on completion.
// IPC handlers use getForActive() to toggle the focused monitor's drawers.
//
// Popups register themselves by id string — no need to add a bool per popup.
// Use toggle(id, screen) / isOpen(state, id) / close(state, id).
Singleton {
    id: root

    property var states: new Map()   // ShellScreen -> VisibilitiesState

    function register(screen, stateObj) {
        states.set(screen, stateObj);
    }

    function getForActive() {
        const primary = Quickshell.screens.find(s => s.primary) ?? Quickshell.screens[0];
        return states.get(primary) ?? null;
    }

    function getForScreen(screen) {
        return states.get(screen) ?? null;
    }

    // Generic toggle: closes all other popups, toggles the requested one.
    function toggle(id, screen) {
        const v = screen ? states.get(screen) : getForActive();
        if (!v)
            return;
        const wasOpen = v.isOpen(id);
        v.closeAll();
        if (!wasOpen)
            v.open(id);
    }

    function closeAllPopups(screen) {
        const v = states.get(screen);
        if (!v)
            return;
        v.closeAll();
    }

    // Convenience shorthands kept for existing callers (WindowTitleWidget, etc.)
    function toggleLauncher(screen) {
        toggle("launcher", screen);
    }
    function togglePower(screen) {
        toggle("power", screen);
    }
    function toggleNetwork(screen) {
        toggle("network", screen);
    }
}
