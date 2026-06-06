import QtQuick
import Quickshell
import "../theme"

// Shared popup frame:
//   - Styled background + border
Rectangle {
    id: root

    anchors.fill: parent

    color: Theme.containerAlpha

    radius: 12

    signal closeRequested
    signal keyPressed(var event)  // ← forward all keys up

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
        } else {
            root.keyPressed(event);
            event.accepted = true;
        }
    }
}
