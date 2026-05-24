import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../theme"
import "../components"

// Battery widget: shows battery level and charging state.
// Polls every 5s as a fallback when UPower displayDevice is stale.
Percentage {
    id: root

    function findBatteryDevice() {
        const devices = UPower.devices;
        for (let i = 0; i < devices.count; i++) {
            const d = devices.get(i);
            if (d.isLaptopBattery) {
                return d;
            }
        }
        return null;
    }

    function refresh() {
        let dev = UPower.displayDevice;
        if (!dev || !dev.ready || dev.percentage == null || dev.percentage === 0) {
            dev = findBatteryDevice();
        }

        if (!dev || !dev.ready) {
            root.icon = "\ud83d\udd0b";
            root.value = "?%";
            return;
        }

        const pct = Math.round(dev.percentage * 100);
        if (isNaN(pct) || pct < 0) {
            root.icon = "\ud83d\udd0b";
            root.value = "?%";
            return;
        }

        const state = dev.state;
        if (state === UPowerDeviceState.FullyCharged) {
            root.icon = "\ud83d\udd0b";
            root.value = "Full";
        } else if (state === UPowerDeviceState.Charging) {
            root.icon = "\ud83d\udd0c";
            root.value = pct + "%";
        } else {
            root.icon = "\ud83d\udd0b";
            root.value = pct + "%";
        }
    }

    Component.onCompleted: root.refresh()

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
