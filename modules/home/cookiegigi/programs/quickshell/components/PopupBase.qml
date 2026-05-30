import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

// Base popup window:
//   - Overlay layer-shell surface
//   - Styled PopupShell frame
//   - Emits opened() / closing() signals for per-popup setup/teardown
//
// Usage: instantiate and add content children. Set visibilityProperty
// to the visibilities key that controls this popup.
//
// Positioning is configurable via anchor*/margin* properties.
// Default setup centers the popup horizontally at the top of the screen.
PanelWindow {
    id: root

    property var visibilities: null
    property string visibilityProperty: ""
    property int popupWidth: 500

    // Positioning
    property bool anchorTop: true
    property bool anchorBottom: false
    property bool anchorLeft: true
    property bool anchorRight: true

    property int marginTop: 15
    property int marginBottom: 0
    property int marginLeft: (screen.width - popupWidth) / 2
    property int marginRight: (screen.width - popupWidth) / 2

    property alias content: popupShell.children
    property alias focusTimer: focusTimer
    property string title: ""

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

    visible: visibilities ? visibilities[visibilityProperty] : false

    WlrLayershell.layer: WlrLayer.Overlay
    exclusiveZone: 0

    implicitWidth: popupWidth
    color: "transparent"

    signal opened()
    signal closing()

    function closePopup() {
        if (visibilities) {
            visibilities[visibilityProperty] = false;
        }
    }

    onVisibleChanged: {
        if (visible) {
            if (title && visibilities) visibilities.popupTitle = title;
            root.opened();
        } else {
            if (visibilities) visibilities.popupTitle = "";
            root.closing();
        }
    }

    PopupShell {
        id: popupShell
        anchors.fill: parent
        onCloseRequested: root.closePopup()
    }

    Timer {
        id: focusTimer
        interval: 100
        repeat: false
    }
}
