import QtQuick
import Quickshell
import "../components"
import "../theme"

// Power menu popup with keyboard-navigable actions.
PopupWindow {
    id: root

    property var visibilities: null

    visible: visibilities ? visibilities.power : false
    grabFocus: true

    implicitWidth: 200
    implicitHeight: menuList.count * 36 + 48
    color: "transparent"

    onVisibleChanged: {
        if (visible) {
            menuList.currentIndex = 0;
            menuList.focus = true;
            focusTimer.start();
        }
    }

    onGrabFocusChanged: {
        if (!grabFocus && visible) {
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
        interval: 50
        repeat: false
        onTriggered: menuList.focus = true
    }
}
