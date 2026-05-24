import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"
import "../services"

// Center widget: shows the active window title.
// Clicking it opens the app launcher on this monitor.
Button {
    id: root

    property var screen: null

    implicitWidth: Math.min(titleText.implicitWidth + Theme.paddingH * 2, 400)
    implicitHeight: titleText.implicitHeight + Theme.paddingV * 2

    StyledText {
        id: titleText
        anchors.centerIn: parent
        width: parent.width - Theme.paddingH * 2
        text: ToplevelManager.activeToplevel?.title ?? ""
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
    }

    onClicked: {
        if (root.screen) {
            Visibilities.toggleLauncher(root.screen);
        }
    }
}
