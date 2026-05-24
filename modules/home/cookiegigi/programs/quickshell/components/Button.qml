import QtQuick
import "../theme"

// Interactive pill button with hover background and pointer cursor.
// Emits clicked() on press.
Pill {
    id: root

    property color hoverBg: Theme.surface1
    signal clicked()

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onEntered: {
            root.color = root.hoverBg;
        }
        onExited: {
            root.color = Theme.containerAlpha;
        }
        onClicked: {
            root.clicked();
        }
    }
}
