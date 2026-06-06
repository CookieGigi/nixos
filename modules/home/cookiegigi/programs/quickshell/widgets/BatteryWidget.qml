import QtQuick
import Quickshell
import "../theme"
import "../components"
import "../services"

// Battery widget: shows battery level and charging state.
// Polls every 5s as a fallback when UPower displayDevice is stale.
Percentage {
    id: root

    Connections {

        target: BatteryStatus
        function onUpdated(): void {
            root.update();
        }
    }

    Component.onCompleted: {
        root.update();
    }

    function update(): void {
        if (!BatteryStatus.ready) {
            root.icon = "";
            root.value = "?%";
            return;
        }

        if (isNaN(BatteryStatus.percentage) || BatteryStatus.percentage < 0) {
            root.icon = "";
            root.value = "?%";
            root.accentColor = Theme.red;
            return;
        }

        if (BatteryStatus.full) {
            root.icon = "";
            root.value = "Full";
            root.accentColor = Theme.green;
        } else if (BatteryStatus.charging) {
            root.icon = "";
            root.value = BatteryStatus.percentage + "%";
            root.accentColor = Theme.text;
        } else {
            if (BatteryStatus.percentage <= 10) {
                root.icon = "";
                root.accentColor = Theme.red;
            } else if (BatteryStatus.percentage <= 25) {
                root.icon = "";
                root.accentColor = Theme.peach;
            } else if (BatteryStatus.percentage <= 50) {
                root.icon = "";
                root.accentColor = Theme.yellow;
            } else if (BatteryStatus.percentage <= 75) {
                root.icon = "";
                root.accentColor = Theme.teal;
            } else {
                root.icon = "";
                root.accentColor = Theme.teal;
            }
            root.value = BatteryStatus.percentage + "%";
        }
    }
}
