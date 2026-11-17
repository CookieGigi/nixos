import QtQuick.Layouts
import Quickshell
import "../components"
import "../theme"
import "../services"

PopupBase {
    id: root
    title: "Bluetooth"
    popupId: "bluetooth"
    popupWidth: 250
    implicitHeight: contentColumn.implicitHeight + 24

    anchorLeft: false
    anchorRight: true

    content: ColumnLayout {
        id: contentColumn
        spacing: 8
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }

        LabelValue {
            label: "Status"
            value: BluetoothStatus.adapterState
        }

        LabelValue {
            visible: BluetoothStatus.isConnected
            label: "Device"
            value: BluetoothStatus.deviceName
        }

        LabelValue {
            visible: BluetoothStatus.isConnected
            label: "Address"
            value: BluetoothStatus.deviceAddress
        }

        LabelValue {
            visible: BluetoothStatus.deviceBatteryAvailable
            label: "Battery"
            value: BluetoothStatus.deviceBattery + "%"
        }

        LabelValue {
            visible: BluetoothStatus.isConnected
            label: "State"
            value: BluetoothStatus.deviceState
        }

        Button {
            implicitWidth: 18
            implicitHeight: 18
            Icon {
                text: ""
                accentColor: parent.isHover ? Theme.accentColor : Theme.text
            }

            onClicked: {
                root.closePopup();
                Quickshell.execDetached(["foot", "-e", "bluetuith"]);
            }
        }
    }
}
