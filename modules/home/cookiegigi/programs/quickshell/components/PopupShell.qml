import QtQuick
import Quickshell
import "../theme"

// Shared popup frame:
//   - Styled background + border
//   - Escape key closes (handled by parent window)
//
// Parent window should grab keyboard focus and wire visible
// to a Visibilities property.
Rectangle {
    id: root

    // Emitted when user presses Escape.
    signal closeRequested()

    anchors.fill: parent

    color: Theme.containerAlpha

    radius: 12

    // Fallback Escape handler (parent PopupWindow should also handle it).
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
        }
    }
}
