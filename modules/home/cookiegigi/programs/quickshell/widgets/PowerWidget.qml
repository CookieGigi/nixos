import QtQuick
import "../theme"
import "../components"
import "../services"

// Power button: toggles the power menu popup on this monitor.
Button {
    id: root

    property var screen: null

    implicitHeight: iconText.implicitHeight + Theme.paddingV * 2
    implicitWidth: iconText.implicitWidth + Theme.paddingH * 2

    Icon {
        id: iconText
        anchors.centerIn: parent
        text: "⏻"
        accentColor: root.isHover ? Theme.accentColor : Theme.text
    }

    onClicked: {
        if (root.screen) {
            PopupRegistry.toggle("power", root.screen);
        }
    }
}
