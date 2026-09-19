import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// Base popup window:
//   - Overlay layer-shell surface
//   - Styled PopupShell frame
//   - Emits opened() / closing() signals for per-popup setup/teardown
//   - Self-contained visibility (isOpen) and keyboard controller (PopupKeyController)
//
// Usage: set popupId to a unique string. Add content children.
// Register with PopupRegistry in Bar.qml.
//
// Positioning is configurable via anchor*/margin* properties.
// Default setup centers the popup horizontally at the top of the screen.
PanelWindow {
    id: root

    // Unique id for this popup. Must match what you pass to PopupRegistry.register().
    property string popupId: ""

    property int popupWidth: 500
    readonly property real screenWidth: screen?.width ?? popupWidth
    readonly property int effectivePopupWidth: Math.max(1, Math.min(popupWidth, screenWidth))

    // Positioning
    property bool anchorTop: true
    property bool anchorBottom: false
    property bool anchorLeft: true
    property bool anchorRight: true

    property int marginTop: 15
    property int marginBottom: 0
    property int marginLeft: Math.round(Math.max(0, Math.min(screenWidth - effectivePopupWidth, computeLeft(anchorWidget))))
    property int marginRight: Math.max(0, screenWidth - marginLeft - effectivePopupWidth)

    property alias content: popupShell.children
    property alias controller: keyController
    property string title: ""

    property var anchorWidget: null
    property string alignment: "center" // "left", "center", "right"

    // Self-contained visibility state
    property bool isOpen: false

    anchors {
        top: anchorTop
        bottom: anchorBottom
        left: anchorLeft
        right: anchorRight
    }
    margins {
        top: marginTop
        bottom: marginBottom
        left: marginLeft
        right: marginRight
    }

    visible: isOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0

    implicitWidth: effectivePopupWidth
    color: "transparent"

    signal opened
    signal closing
    signal unhandledKeyPressed(var event)

    function computeLeft(w) {
        if (!w)
            return (screenWidth - effectivePopupWidth) / 2;
        // mapToItem does not establish dependencies on ancestor positions.
        for (let item = w; item; item = item.parent)
            void item.x;
        const pos = w.mapToItem(null, 0, 0);
        if (alignment === "left")
            return pos.x;
        if (alignment === "right")
            return pos.x + w.width - effectivePopupWidth;
        return pos.x + w.width / 2 - effectivePopupWidth / 2;
    }
    function closePopup() {
        isOpen = false;
    }

    onVisibleChanged: {
        if (visible) {
            hiddenInput.forceActiveFocus();
            root.opened();
        } else {
            root.closing();
        }
    }

    PopupKeyController {
        id: keyController
        popupTitle: root.title
        onClose: root.closePopup()
    }

    // Hidden TextInput that receives real keyboard events when popup is focused.
    // This preserves native typing, copy/paste, cursor movement, IME, etc.
    // Navigation keys (Escape, Enter, Up, Down) are intercepted by handleKey().
    TextInput {
        id: hiddenInput
        visible: false
        text: keyController.searchText
        onTextChanged: {
            if (keyController.searchText !== text) {
                keyController.searchText = text;
                keyController.searchTextChanged();
            }
        }
        Keys.onPressed: event => {
            keyController.handleKey(event);
            if (!event.accepted) {
                root.unhandledKeyPressed(event);
            }
        }
    }

    PopupShell {
        id: popupShell
        anchors.fill: parent
        onCloseRequested: root.closePopup()
        onKeyPressed: event => {
        // hiddenInput.Keys.onPressed already fires first and handles the key.
        // If the event is not accepted by the time it reaches here, it means
        // neither PopupKeyController nor the popup's unhandledKeyPressed handler
        // consumed it. Let it propagate further if needed.
        }
    }
}
