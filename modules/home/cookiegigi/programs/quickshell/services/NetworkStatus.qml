pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── connection state ──────────────────────────────
    readonly property bool hasConnection: _hasConnection
    readonly property string connectionType: _connectionType  // "wifi" | "ethernet" | ""
    readonly property string connectionName: _connectionName
    readonly property string device: _device

    // ── wifi-only ─────────────────────────────────────
    readonly property int signalStrength: _signalStrength     // 0–100
    readonly property string frequency: _frequency            // "2.4 GHz" | "5 GHz" | "6 GHz"
    readonly property string bssid: _bssid
    readonly property string security: _security

    // ── ethernet-only ─────────────────────────────────
    readonly property string speed: _speed

    // ─────────────────────────────────────────────────
    function refresh() {
        connectionProcess.running = true;
    }
    Component.onCompleted: root.refresh()

    // ── backing props ─────────────────────────────────
    property bool _hasConnection: false
    property string _connectionType: ""
    property string _connectionName: ""
    property string _device: ""
    property int _signalStrength: 0
    property string _frequency: ""
    property string _bssid: ""
    property string _security: ""
    property string _speed: ""

    property var _connectionProcess: Process {
        id: connectionProcess
        command: ["nmcli", "-t", "-f", "TYPE,NAME,DEVICE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.trim() !== "");
                let wifi = false, eth = false;
                root._connectionType = "";
                root._connectionName = "";
                root._device = "";

                for (const line of lines) {
                    const parts = line.split(":");
                    if (parts.length < 3)
                        continue;
                    const type = parts[0];
                    const device = parts[parts.length - 1];
                    const name = parts.slice(1, parts.length - 1).join(":");

                    if (type.includes("wireless") || type === "802-11-wireless") {
                        wifi = true;
                        root._connectionType = "wifi";
                        root._connectionName = name;
                        root._device = device;
                    } else if (!wifi && (type.includes("ethernet") || type === "802-3-ethernet")) {
                        eth = true;
                        root._connectionType = "ethernet";
                        root._connectionName = name;
                        root._device = device;
                    }
                }

                root._hasConnection = wifi || eth;

                if (wifi) {
                    wifiDetailProcess.running = true;
                } else {
                    root._signalStrength = 0;
                    root._frequency = "";
                    root._bssid = "";
                    root._security = "";
                    if (eth)
                        ethernetDetailProcess.running = true;
                    else
                        root._speed = "";
                }
            }
        }
    }

    property var _wifiDetailProcess: Process {
        id: wifiDetailProcess
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,FREQ,BSSID,SECURITY", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.trim() !== "");
                for (const line of lines) {
                    const parts = line.split(/:(?!\\)/).map(p => p.replace(/\\:/g, ":"));
                    if (parts.length < 6)
                        continue;
                    if (parts[0] !== "*")
                        continue;
                    const freq = parts[3];
                    root._signalStrength = parseInt(parts[2]) || 0;
                    root._frequency = freq.includes("6") ? "6 GHz" : freq.includes("5") ? "5 GHz" : "2.4 GHz";
                    root._bssid = parts[4];
                    root._security = parts[5];
                    break;
                }
            }
        }
    }

    property var _ethernetDetailProcess: Process {
        id: ethernetDetailProcess
        command: ["nmcli", "-t", "-f", "GENERAL.SPEED", "dev", "show", root._device]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.split("\n").find(l => l.includes("SPEED"));
                if (line) {
                    const val = line.split(":").slice(1).join(":").trim();
                    root._speed = val === "Unknown" ? "" : val;
                } else {
                    root._speed = "";
                }
            }
        }
    }

    property var _monitor: Process {
        id: nmMonitor
        command: ["nmcli", "monitor"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.refresh()
        }
    }
}
