import QtQuick
import Quickshell
import "../theme"

// Shared popup frame:
//   - Styled background + border
//   - Escape key closes
//   - Click outside the content area closes
//
// Parent PopupWindow should set grabFocus: true and
// wire visible to a Visibilities property.
Rectangle {
    id: root

    // Emitted when user presses Escape or clicks outside.
    signal closeRequested()

    // Inner content area.
    property alias innerContent: contentArea.children

    anchors.fill: parent
    color: Theme.popupBg
    radius: 12
    border.width: 2
    border.color: Theme.popupBorder

    // Focus: arrow keys → list, other text keys → search bar
    // (handled by parent; this just provides the Keys.onPressed hook)
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
        }
    }

    // Inner content area
    Item {
        id: contentArea
        anchors {
            fill: parent
            margins: 12
        }
    }

    // Full-screen transparent click catcher behind the popup
    // but above the rest of the shell (z: -1 is relative to siblings here,
    // so we place it as a sibling with lower z and fill the parent PopupWindow).
    MouseArea {
        id: outsideClick
        anchors.fill: parent
        z: -1
        onClicked: {
            root.closeRequested();
        }
    }
}
