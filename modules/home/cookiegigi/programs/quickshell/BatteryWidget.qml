import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

// A widget that shows the system battery level using UPower,
// wrapped in a rounded pill container.
Rectangle {
    id: root
    radius: 8
    color: "#b324273a"
    implicitHeight: batteryLayout.implicitHeight + 12
    implicitWidth: batteryLayout.implicitWidth + 24

    // UPower.displayDevice is a constant property, so bindings may not
    // re-evaluate when it becomes ready or updates. We poll every 5s
    // to ensure the widget stays current.
    property string batteryIcon: "🔋"
    property string batteryText: "?%"

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
        // displayDevice can be stale or return 0% on some systems;
        // fall back to the actual laptop battery device from devices.
        if (!dev || !dev.ready || dev.percentage == null || dev.percentage === 0) {
            dev = findBatteryDevice();
        }

        if (!dev || !dev.ready) {
            root.batteryIcon = "🔋";
            root.batteryText = "?%";
            return;
        }

        const pct = Math.round(dev.percentage * 100);
        if (isNaN(pct) || pct < 0) {
            root.batteryIcon = "🔋";
            root.batteryText = "?%";
            return;
        }

        const state = dev.state;
        if (state === UPowerDeviceState.FullyCharged) {
            root.batteryIcon = "🔋";
            root.batteryText = "Full";
        } else if (state === UPowerDeviceState.Charging) {
            root.batteryIcon = "🔌";
            root.batteryText = pct + "%";
        } else {
            root.batteryIcon = "🔋";
            root.batteryText = pct + "%";
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    RowLayout {
        id: batteryLayout
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.batteryIcon
            color: "#8bd5ca"
            font.pixelSize: 14
        }

        Text {
            text: root.batteryText
            color: "#8bd5ca"
            font {
                family: "monospace"
                pixelSize: 14
                bold: true
            }
        }
    }
}
