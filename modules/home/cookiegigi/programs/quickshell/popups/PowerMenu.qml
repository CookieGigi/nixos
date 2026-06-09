import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../theme"

// Power menu popup with keyboard-navigable actions.
// Positioned under the power button in the top-right bar area.
PopupBase {
    id: root

    title: "Power Menu"
    popupId: "power"
    popupWidth: 200

    anchorLeft: false
    anchorRight: true

    implicitHeight: Math.min(400, menuList.count * 36 + 48)

    property var actions: [
        {
            label: "Shutdown",
            cmd: ["systemctl", "poweroff"]
        },
        {
            label: "Reboot",
            cmd: ["systemctl", "reboot"]
        },
        {
            label: "Suspend",
            cmd: ["systemctl", "suspend"]
        },
        {
            label: "Logout",
            cmd: ["niri", "msg", "action", "quit"]
        },
        {
            label: "Cancel",
            cmd: null
        }
    ]

    onOpened: {
        menuList.currentIndex = 0;
    }

    Component.onCompleted: {
        controller.navigateDown.connect(menuList.incrementCurrent);
        controller.navigateUp.connect(menuList.decrementCurrent);
        controller.activate.connect(menuList.activateCurrent);
    }

    content: ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 8

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            SelectionList {
                id: menuList
                anchors.fill: parent
                anchors.margins: 10
                items: root.actions.map(a => ({
                            label: a.label
                        }))

                onEscapePressed: root.closePopup()

                onItemActivated: index => {
                    const action = root.actions[index];
                    if (action && action.cmd) {
                        Quickshell.execDetached(action.cmd);
                    }
                    root.closePopup();
                }
            }
        }
    }
}
