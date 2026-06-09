import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "../components"
import "../services"

// Network widget: shows a WiFi or Ethernet icon based on the active connection.
Button {
    id: root

    visible: NetworkStatus.hasConnection
    property var screen: null

    implicitWidth: netLayout.implicitWidth + Theme.paddingH * 2
    implicitHeight: netLayout.implicitHeight + Theme.paddingV * 2

    RowLayout {
        id: netLayout
        anchors.centerIn: parent
        spacing: 6

        Icon {
            accentColor: root.isHover ? Theme.accentColor : Theme.text
            text: NetworkStatus.connectionType === "wifi" ? "" : ""
        }
    }

    onClicked: {
        if (root.screen) {
            PopupRegistry.toggleNetwork(root.screen);
        }
    }
}
