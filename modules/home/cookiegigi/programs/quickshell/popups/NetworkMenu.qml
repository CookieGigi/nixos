import QtQuick.Layouts
import "../components"
import "../theme"
import "../services"

PopupBase {
    id: root
    title: "Network Menu"
    popupId: "networkMenu"
    popupWidth: 250

    anchorLeft: false
    anchorRight: true

    content: ColumnLayout {

        spacing: 8
        anchors {
            fill: parent
            margins: 12
        }

        LabelValue {
            label: "Name"
            value: NetworkStatus.connectionName
        }
        LabelValue {
            label: "Device"
            value: NetworkStatus.connectionType + "(" + NetworkStatus.device + ")"
        }
        LabelValue {
            visible: NetworkStatus.connectionType == "wifi"
            label: "Frequency"
            value: NetworkStatus.frequency
        }
        LabelValue {
            visible: NetworkStatus.connectionType == "ethernet"
            label: "Speed"
            value: NetworkStatus.speed
        }
    }
}
