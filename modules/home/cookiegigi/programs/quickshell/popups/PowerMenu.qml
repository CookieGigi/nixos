import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../theme"

// Power menu popup with keyboard-navigable actions.
// Uses PanelWindow with Overlay layer so it works on compositors
// (e.g. niri) where xdg_popup cannot attach to a layer-shell parent.
PanelWindow {
    id: root

    property var visibilities: null

    visible: visibilities ? visibilities.power : false

    // Overlay layer-shell surface: floats above everything, grabs keyboard.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusiveZone: 0

    implicitWidth: 200
    implicitHeight: menuList.count * 36 + 48
    color: "transparent"

    onVisibleChanged: {
        if (visible) {
            menuList.currentIndex = 0;
            menuList.forceActiveFocus();
            focusTimer.start();
        } else {
            closePower();
        }
    }

    property var actions: [
        { label: "Shutdown", cmd: ["systemctl", "poweroff"] },
        { label: "Reboot",   cmd: ["systemctl", "reboot"] },
        { label: "Suspend",  cmd: ["systemctl", "suspend"] },
        { label: "Logout",   cmd: ["niri", "msg", "action", "quit"] },
        { label: "Cancel",   cmd: null }
    ]

    function closePower() {
        if (visibilities) {
            visibilities.power = false;
        }
    }

    PopupShell {
        anchors.fill: parent

        onCloseRequested: root.closePower()

        SelectionList {
            id: menuList
            anchors.fill: parent
            focus: true
            items: root.actions.map(a => ({ label: a.label }))

            onEscapePressed: root.closePower()

            onItemActivated: (index) => {
                const action = root.actions[index];
                if (action && action.cmd) {
                    Quickshell.execDetached(action.cmd);
                }
                root.closePower();
            }
        }
    }

    Timer {
        id: focusTimer
        interval: 100
        repeat: false
        onTriggered: menuList.forceActiveFocus()
    }
}
