import QtQuick
import Quickshell
import "../theme"

// Shared popup frame:
//   - Styled background + border
//   - Only Escape is handled here (closes popup)
//   - All other keys are forwarded up to PopupBase for processing
//     (PopupKeyController intercepts navigation keys; rest falls through to TextInput)
Rectangle {
    id: root

    anchors.fill: parent

    color: Theme.containerAlpha

    radius: 12

    signal closeRequested
    signal keyPressed(var event)  // ← forward keys up

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
        } else {
            root.keyPressed(event);
            // Do NOT set event.accepted = true — let unhandled keys propagate
            // to the hidden TextInput for native typing, copy/paste, etc.
        }
    }
}
