import QtQuick

// PopupKeyController: per-popup keyboard controller.
// Instantiates inside PopupBase. Handles only navigation keys,
// leaving all other keys (typing, copy/paste, etc.) to the native TextInput.
//
// Signals:
//   - navigateDown, navigateUp, activate, close
//   - searchTextChanged (when typing changes searchText)
//
// Usage: call handleKey(event) from PopupShell.Keys.onPressed.
QtObject {
    id: root

    property string searchText: ""
    property string popupTitle: ""
    property bool handleLeftRight: false

    signal navigateDown
    signal navigateUp
    signal navigateLeft
    signal navigateRight
    signal activate
    signal close

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            root.close();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activate();
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            root.navigateDown();
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            root.navigateUp();
            event.accepted = true;
        } else if (root.handleLeftRight && event.key === Qt.Key_Left) {
            root.navigateLeft();
            event.accepted = true;
        } else if (root.handleLeftRight && event.key === Qt.Key_Right) {
            root.navigateRight();
            event.accepted = true;
        }
        // All other keys (typing, copy/paste, etc.) fall through to native TextInput.
    }
}
