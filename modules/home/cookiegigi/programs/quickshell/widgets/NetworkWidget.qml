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

    Process {
        id: nmMonitor
        command: ["nmcli", "monitor"]
        stdout: StdioCollector {
            onStreamFinished: root.refresh()
        }
        running: true
    }

    Process {
        id: nmProcess
        command: ["nmcli", "-t", "-f", "TYPE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                let wifiConnected = false;
                let ethernetConnected = false;
                for (const line of lines) {
                    if (line.includes("wireless"))
                        wifiConnected = true;
                    else if (line.includes("eth"))
                        ethernetConnected = true;
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
            accentColor: Theme.text
            text: root.connectionType === "wifi" ? "" : ""
        }
    }
}
