import QtQuick
import QtQuick.Layouts
import Quickshell

// A power menu popup anchored below the power button.
PopupWindow {
    id: root

    // Width and height sized to fit the menu items.
    implicitWidth: 200
    implicitHeight: menuCol.implicitHeight + 24
    color: "transparent"

    grabFocus: true

    // Close when the compositor clears the grab (outside click, etc.).
    onGrabFocusChanged: {
        if (!grabFocus) {
            root.visible = false;
        }
    }

    property var actions: [
        { label: "Shutdown", cmd: ["systemctl", "poweroff"] },
        { label: "Reboot",   cmd: ["systemctl", "reboot"] },
        { label: "Suspend",  cmd: ["systemctl", "suspend"] },
        { label: "Logout",   cmd: ["niri", "msg", "action", "quit"] },
        { label: "Cancel",   cmd: null }
    ]

    function executeAction(index) {
        const action = actions[index];
        if (action.cmd) {
            Quickshell.execDetached(action.cmd);
        }
        root.visible = false;
    }

    // Main container.
    Rectangle {
        anchors.fill: parent
        color: "#24273a"
        radius: 12
        border.width: 2
        border.color: "#8bd5ca"

        // Global key handler on the root rectangle.
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.visible = false;
                event.accepted = true;
            }
        }

        ColumnLayout {
            id: menuCol
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 4

            Repeater {
                model: root.actions

                delegate: Rectangle {
                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: labelText.implicitHeight + 14
                    radius: 6
                    color: hoverArea.containsMouse ? "#494d64" : "transparent"

                    Text {
                        id: labelText
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: 10
                        }
                        text: modelData.label
                        color: hoverArea.containsMouse ? "#8bd5ca" : "#cad3f5"
                        font {
                            family: "monospace"
                            pixelSize: 13
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.executeAction(index)
                    }
                }
            }
        }
    }
}
