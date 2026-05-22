import QtQuick
import Quickshell

// A clickable power button wrapped in a rounded pill container.
Rectangle {
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
            color: "#8bd5ca"
            font {
                family: "monospace"
                pixelSize: 14
                bold: true
            }
        }

        onClicked: {
            Quickshell.execDetached(["sh", "-c", "power-menu"]);
        }
    }
}
