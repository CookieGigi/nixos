import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components"
import "../services"

// Keep settings accessible even when the adapter is powered off.
// Icon changes when a device is connected.
Button {
    id: root

    visible: BluetoothStatus.hasAdapter
    property var screen: null

    implicitWidth: btLayout.implicitWidth + Theme.paddingH * 2
    implicitHeight: btLayout.implicitHeight + Theme.paddingV * 2

    RowLayout {
        id: btLayout
        anchors.centerIn: parent
        spacing: 6

        Icon {
            accentColor: root.isHover ? Theme.accentColor : (BluetoothStatus.isPowered ? Theme.text : Theme.overlay0)
            text: !BluetoothStatus.isPowered ? "󰂲" : (BluetoothStatus.isConnected ? "󰂱" : "")
        }
    }

    onClicked: {
        if (root.screen) {
            PopupRegistry.toggleBluetooth(root.screen);
        }
    }
}
