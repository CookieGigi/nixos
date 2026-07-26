pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    // ── adapter state ─────────────────────────────────
    readonly property bool hasAdapter: Bluetooth.defaultAdapter !== null
    readonly property bool isPowered: hasAdapter && Bluetooth.defaultAdapter.enabled
    readonly property bool isDiscoverable: hasAdapter && Bluetooth.defaultAdapter.discoverable
    readonly property string adapterState: {
        if (!hasAdapter)
            return "none";
        switch (Bluetooth.defaultAdapter.state) {
        case BluetoothAdapterState.Disabled:
            return "off";
        case BluetoothAdapterState.Enabling:
            return "enabling";
        case BluetoothAdapterState.Enabled:
            return "on";
        case BluetoothAdapterState.Disabling:
            return "disabling";
        case BluetoothAdapterState.Blocked:
            return "blocked";
        default:
            return "unknown";
        }
    }

    // ── connection state ────────────────────────────────
    readonly property bool isConnected: Bluetooth.devices.count > 0
    readonly property string deviceName: isConnected ? Bluetooth.devices.objectAt(0).name : ""
    readonly property string deviceAddress: isConnected ? Bluetooth.devices.objectAt(0).address : ""
    readonly property string deviceIcon: isConnected ? Bluetooth.devices.objectAt(0).icon : ""
    readonly property int deviceBattery: isConnected && Bluetooth.devices.objectAt(0).batteryAvailable ? Math.round(Bluetooth.devices.objectAt(0).battery * 100) : -1
    readonly property bool deviceBatteryAvailable: isConnected && Bluetooth.devices.objectAt(0).batteryAvailable
    readonly property string deviceState: {
        if (!isConnected)
            return "";
        switch (Bluetooth.devices.objectAt(0).state) {
        case BluetoothDeviceState.Connected:
            return "connected";
        case BluetoothDeviceState.Connecting:
            return "connecting";
        case BluetoothDeviceState.Disconnecting:
            return "disconnecting";
        default:
            return "";
        }
    }

    // ── count of connected devices ──────────────────────
    readonly property int connectedCount: Bluetooth.devices.count
}
