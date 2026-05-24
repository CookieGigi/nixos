import QtQuick
import Quickshell
import "../theme"

// Shared popup frame:
//   - Styled background + border
//   - Escape key closes (handled by parent PopupWindow)
//
// Parent PopupWindow should set grabFocus: true and
// wire visible to a Visibilities property.
Rectangle {
    id: root

    // Emitted when user presses Escape.
    signal closeRequested()

    anchors.fill: parent
    color: Theme.popupBg
    radius: 12
    border.width: 2
    border.color: Theme.popupBorder

    // Fallback Escape handler (parent PopupWindow should also handle it).
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
        }
    }
}
