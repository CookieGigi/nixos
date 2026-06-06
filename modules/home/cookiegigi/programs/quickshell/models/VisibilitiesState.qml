import QtQuick

// Per-screen popup state. Instantiated by Bar, registered with Visibilities singleton.
// Replaces hardcoded `property bool launcher / power` with a dynamic id map.
//
// Usage:
//   isOpen("launcher")   → bool
//   open("launcher")     → opens it
//   close("launcher")    → closes it
//   closeAll()           → closes everything
QtObject {
    id: root

    // Internal open-state map: id (string) -> bool
    property var _open: ({})

    // Notifier — increment to trigger bindings that call isOpen()
    property int _rev: 0

    function isOpen(id) {
        void _rev; // depend on revision so bindings re-evaluate
        return _open[id] ?? false;
    }

    function open(id) {
        _open[id] = true;
        _rev++;
    }

    function close(id) {
        _open[id] = false;
        _rev++;
    }

    function closeAll() {
        _open = {};
        _rev++;
    }

    // ── Launcher-specific extras (used by WindowTitleWidget) ──────────────

    property string launcherFilter: ""
    property string popupTitle: ""

    // Signals forwarded to AppLauncher for keyboard nav
    signal launcherActivate
    signal launcherIncrement
    signal launcherDecrement
}
