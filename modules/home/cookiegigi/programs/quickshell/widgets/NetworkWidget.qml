import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "../components"

// Network widget: shows a WiFi or Ethernet icon based on the active connection.
Pill {
    id: root

    visible: root.hasConnection

    property bool hasConnection: false
    property string connectionType: ""

    implicitWidth: netLayout.implicitWidth + Theme.paddingH * 2
    implicitHeight: netLayout.implicitHeight + Theme.paddingV * 2

    function refresh() {
        nmProcess.running = true;
    }

    Component.onCompleted: root.refresh()

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: nmProcess
        command: ["nmcli", "-t", "-f", "TYPE,STATE", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                let wifiConnected = false;
                let ethernetConnected = false;
                for (const line of lines) {
                    const parts = line.split(":");
                    if (parts.length < 2) continue;
                    const type = parts[0];
                    const state = parts[1];
                    if (state.startsWith("connected")) {
                        if (type === "wifi") wifiConnected = true;
                        else if (type === "ethernet") ethernetConnected = true;
                    }
                }
                if (ethernetConnected) {
                    root.connectionType = "ethernet";
                    root.hasConnection = true;
                } else if (wifiConnected) {
                    root.connectionType = "wifi";
                    root.hasConnection = true;
                } else {
                    root.hasConnection = false;
                }
            }
        }
    }

    RowLayout {
        id: netLayout
        anchors.centerIn: parent
        spacing: 6

        Icon {
            text: root.connectionType === "wifi" ? "\ud83d\udcf6" : "\ud83d\udda7"
        }
    }
}
