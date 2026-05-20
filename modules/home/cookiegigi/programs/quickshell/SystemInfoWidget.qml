import QtQuick
import QtQuick.Layouts
import Quickshell

// A floating widget that shows some basic system info.
// FloatingWindow is for standard desktop windows (not panels).
Scope {
    id: root

    // A small popup window in the bottom-right corner.
    FloatingWindow {
        // Position near the bottom-right of the screen.
        // Since FloatingWindow is not anchored like PanelWindow,
        // we use x/y with screen geometry.
        x: screen.width - width - 20
        y: screen.height - height - 20

        implicitWidth: 280
        implicitHeight: 140
        color: "#cc1a1a2e" // matches the bar background

        // A rounded rectangle background.
        Rectangle {
            anchors.fill: parent
            color: parent.color
            radius: 12

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 16
                }
                spacing: 8

                Text {
                    text: "System Info"
                    color: "#89b4fa"
                    font {
                        family: "monospace"
                        pixelSize: 16
                        bold: true
                    }
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: "#45475a"
                }

                Text {
                    // Qt.platform.os gives the OS name.
                    text: "OS: " + Qt.platform.os
                    color: "#cdd6f4"
                    font {
                        family: "monospace"
                        pixelSize: 13
                    }
                }

                Text {
                    // screen.name gives the monitor name.
                    text: "Screen: " + (screen?.name ?? "unknown")
                    color: "#cdd6f4"
                    font {
                        family: "monospace"
                        pixelSize: 13
                    }
                }

                Text {
                    text: "Resolution: " + screen.width + "x" + screen.height
                    color: "#cdd6f4"
                    font {
                        family: "monospace"
                        pixelSize: 13
                    }
                }

                // Live clock in the popup as well.
                Text {
                    text: "Time: " + Time.time
                    color: "#cdd6f4"
                    font {
                        family: "monospace"
                        pixelSize: 13
                    }
                }
            }
        }
    }
}
