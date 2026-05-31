import QtQuick
import "../theme"

// Interactive pill button with hover background and pointer cursor.
// Emits clicked() on press.
Pill {
    id: root

    signal clicked

    property bool isHover: false

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onEntered: {
            isHover = true;
        }
        onExited: {
            isHover = false;
        }
        onClicked: {
            root.clicked();
        }
    }
}
