import QtQuick
import "../theme"

// Interactive pill button with hover background and pointer cursor.
// Emits clicked() on press.
Pill {
    id: root

    signal clicked

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.clicked();
        }
    }
}
