pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Reactive battery singleton — no polling, event-driven via UPower signals
Singleton {

    // --- ALTERNATIVE APPROACH (commented out) ---
    // If you need a fallback for misbehaving UPower daemons, re-enable this.
    // TRADEOFF: wastes CPU, delays up to interval ms, but always catches changes.
    //
    // Timer {
    //     interval: 30000   // 30s fallback — much rarer than original 5s
    //     running: true
    //     repeat: true
    //     onTriggered: root.updated()
    // }

    id: root

    // --- Public API ---
    readonly property bool ready: UPower.displayDevice?.ready ?? false

    // 0.0–100.0 (rounded)
    readonly property real percentage: ready ? Math.round(UPower.displayDevice.percentage * 100) : 0

    // UPowerDeviceState enum: 0=Unknown 1=Charging 2=Discharging 3=Empty
    //                         4=FullyCharged 5=PendingCharge 6=PendingDischarge
    readonly property int status: ready ? UPower.displayDevice.state : UPowerDeviceState.Unknown

    // Convenience booleans derived from state
    readonly property bool charging: status === UPowerDeviceState.Charging || status === UPowerDeviceState.PendingCharge
    readonly property bool full: status === UPowerDeviceState.FullyCharged

    // Time-to-empty/full in seconds. -1 = not estimating.
    readonly property real timeToEmpty: ready ? UPower.displayDevice.timeToEmpty : -1
    readonly property real timeToFull: ready ? UPower.displayDevice.timeToFull : -1

    signal updated

    // --- Reactive: fires when percentage changes ---
    // WHY: UPower emits onPercentageChanged itself. No need to poll.
    // TRADEOFF: If UPower daemon crashes, no updates until restart.
    //           Polling would recover automatically — but wastes CPU always.
    Connections {
        target: UPower.displayDevice
        function onPercentageChanged(): void {
            root.updated();
        }
        function onStateChanged(): void {
            root.updated();
        }
        function onReadyChanged(): void {
            root.updated();
        }
    }

    // --- Reactive: fires when charger plugged/unplugged ---
    Connections {
        target: UPower
        function onOnBatteryChanged(): void {
            root.updated();
        }
    }
}
