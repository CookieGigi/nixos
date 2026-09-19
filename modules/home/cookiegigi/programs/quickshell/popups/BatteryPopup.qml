import QtQuick.Layouts
import Quickshell.Services.UPower
import "../components"
import "../theme"
import "../services"

PopupBase {
    id: root
    title: "Battery"
    popupId: "battery"
    popupWidth: 250

    content: ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 8

        LabelValue {
            label: "Percentage"
            value: BatteryStatus.ready ? BatteryStatus.percentage + "%" : "N/A"
        }

        LabelValue {
            label: "Status"
            value: {
                if (!BatteryStatus.ready)
                    return "N/A";
                switch (BatteryStatus.status) {
                case UPowerDeviceState.FullyCharged:
                    return "Fully Charged";
                case UPowerDeviceState.Charging:
                    return "Charging";
                case UPowerDeviceState.Discharging:
                    return "Discharging";
                case UPowerDeviceState.Empty:
                    return "Empty";
                case UPowerDeviceState.PendingCharge:
                    return "Pending Charge";
                case UPowerDeviceState.PendingDischarge:
                    return "Pending Discharge";
                default:
                    return "Unknown";
                }
            }
        }

        LabelValue {
            visible: BatteryStatus.ready && BatteryStatus.timeToEmpty > 0
            label: "Time to Empty"
            value: formatTime(BatteryStatus.timeToEmpty)
        }

        LabelValue {
            visible: BatteryStatus.ready && BatteryStatus.timeToFull > 0
            label: "Time to Full"
            value: formatTime(BatteryStatus.timeToFull)
        }
    }

    function formatTime(seconds) {
        if (seconds <= 0)
            return "";
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        return h + "h " + m + "m";
    }
}
