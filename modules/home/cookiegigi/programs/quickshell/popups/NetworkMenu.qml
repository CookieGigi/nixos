import QtQuick.Layouts
import Quickshell
import "../components"
import "../theme"
import "../services"

PopupBase {
    id: root
    title: "Network Menu"
    popupId: "network"
    popupWidth: 250
    implicitHeight: 150

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
        Button {

            implicitWidth: 18
            implicitHeight: 18
            Icon {
                text: ""
                accentColor: parent.isHover ? Theme.accentColor : Theme.text
            }

            onClicked: {
                root.closePopup();
                Quickshell.execDetached(["foot", "-a", "quickshell-tui", "-e", "wifitui"]);
            }
        }
    }
}
