import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components"
import "../services"

// Bluetooth widget: shows when the adapter is powered.
// Icon changes when a device is connected.
Button {
    id: root

    visible: BluetoothStatus.hasAdapter && BluetoothStatus.isPowered
    property var screen: null

    implicitWidth: btLayout.implicitWidth + Theme.paddingH * 2
    implicitHeight: btLayout.implicitHeight + Theme.paddingV * 2

    RowLayout {
        id: btLayout
        anchors.centerIn: parent
        spacing: 6

        Icon {
            accentColor: root.isHover ? Theme.accentColor : Theme.text
            text: BluetoothStatus.isConnected ? "󰂱" : ""
        }
    }

    onClicked: {
        if (root.screen) {
            PopupRegistry.toggleBluetooth(root.screen);
        }
    }
}
