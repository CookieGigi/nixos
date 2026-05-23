import QtQuick
import Quickshell

// A clickable power button wrapped in a rounded pill container.
Rectangle {
    id: root

    property var powerMenuRef: null

    radius: 8
    color: "#b324273a"
    implicitHeight: powerText.implicitHeight + 12
    implicitWidth: powerText.implicitWidth + 24

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        Text {
            id: powerText
            anchors.centerIn: parent
            text: "⏻"
            color: "#ffffff"
            font {
                family: "monospace"
                pixelSize: 14
                bold: true
            }
        }

        onClicked: {
            if (root.powerMenuRef) {
                root.powerMenuRef.visible = true;
            }
        }
    }
}
