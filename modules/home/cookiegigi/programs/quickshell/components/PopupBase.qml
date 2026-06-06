import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// Base popup window:
//   - Overlay layer-shell surface
//   - Styled PopupShell frame
//   - Emits opened() / closing() signals for per-popup setup/teardown
//
// Usage: set popupId to a unique string. Add content children.
// No need to touch Visibilities when adding a new popup.
//
// Positioning is configurable via anchor*/margin* properties.
// Default setup centers the popup horizontally at the top of the screen.
PanelWindow {
    id: root

    property var visibilities: null

    // Unique id for this popup. Must match what you pass to Visibilities.toggle().
    property string popupId: ""

    property int popupWidth: 500

    // Positioning
    property bool anchorTop: true
    property bool anchorBottom: false
    property bool anchorLeft: true
    property bool anchorRight: true

    property int marginTop: 15
    property int marginBottom: 0
    property int marginLeft: anchorWidget ? computeLeft(anchorWidget) : (screen.width - popupWidth) / 2
    property int marginRight: screen.width - marginLeft - popupWidth

    property alias content: popupShell.children
    property alias focusTimer: focusTimer
    property string title: ""

    property var anchorWidget: null
    property string alignment: "center" // "left", "center", "right"

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

    // Depends on _rev so binding re-evaluates when any popup opens/closes
    visible: visibilities ? visibilities.isOpen(popupId) : false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0

    implicitWidth: popupWidth
    color: "transparent"

    signal opened
    signal closing

    function computeLeft(w) {
        if (!anchorWidget)
            return (screen.width - popupWidth) / 2;
        void anchorWidget.x;  // force dependency
        void anchorWidget.width;
        const pos = anchorWidget.mapToItem(null, 0, 0);
        if (alignment === "left")
            return pos.x;
        if (alignment === "right")
            return pos.x + anchorWidget.width - popupWidth;
        return pos.x + anchorWidget.width / 2 - popupWidth / 2;
    }
    function closePopup() {
        if (visibilities) {
            visibilities.close(popupId);
        }
    }

    onVisibleChanged: {
        if (visible) {
            popupShell.forceActiveFocus();
            if (title && visibilities)
                visibilities.popupTitle = title;
            root.opened();
        } else {
            if (visibilities)
                visibilities.popupTitle = "";
            root.closing();
        }
    }

    PopupShell {
        id: popupShell
        anchors.fill: parent
        onCloseRequested: root.closePopup()
        onKeyPressed: event => root.keyPressed(event)
    }

    Timer {
        id: focusTimer
        interval: 100
        repeat: false
    }

    signal keyPressed(var event)
}
