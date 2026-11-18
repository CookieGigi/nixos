pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool ready: false
    property int percentage: 0
    property int _requestedPercentage: -1

    function refresh(): void {
        if (!brightnessProcess.running) {
            brightnessProcess.running = true;
        }
    }

    function setPercentage(value: int): void {
        root._requestedPercentage = Math.max(0, Math.min(100, Math.round(value)));
        root.percentage = root._requestedPercentage;
    }

    Process {
        id: brightnessProcess
        command: ["brightnessctl", "--class=backlight", "-m"]

        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim().split("\n").find(entry => entry !== "");
                if (!line) {
                    root.ready = false;
                    return;
                }

                const fields = line.split(",");
                const percentage = parseInt(fields[3]);
                if (!Number.isFinite(percentage)) {
                    root.ready = false;
                    return;
                }

                root.percentage = Math.max(0, Math.min(100, percentage));
                root.ready = true;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    console.warn("brightnessctl read:", text.trim());
                }
            }
        }
    }

    Process {
        id: setBrightnessProcess
        command: ["brightnessctl", "--class=backlight", "set", root._requestedPercentage + "%"]

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    console.warn("brightnessctl set:", text.trim());
                }
            }
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true

        onTriggered: {
            if (root._requestedPercentage >= 0 && !setBrightnessProcess.running) {
                setBrightnessProcess.command = ["brightnessctl", "--class=backlight", "set", root._requestedPercentage + "%"];
                root._requestedPercentage = -1;
                setBrightnessProcess.running = true;
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
