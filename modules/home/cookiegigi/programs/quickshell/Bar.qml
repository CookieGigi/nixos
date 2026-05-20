import QtQuick
import QtQuick.Layouts
import Quickshell

// A top panel bar that appears on every connected monitor.
// PanelWindow is Quickshell's type for bars, widgets, and overlays.
Scope {
    id: root

    // Variants creates an instance of its delegate for every item in the model.
    // Here we use Quickshell.screens so a bar appears on each monitor.
    // If you plug/unplug monitors, bars are created and destroyed automatically.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            // modelData is injected by Variants and contains the screen object.
            required property var modelData
            screen: modelData

            // Anchor the bar to the top of the screen and stretch across it.
            anchors {
                top: true
                left: true
                right: true
            }

            // Reserve space so other windows don't overlap the bar.
            exclusiveZone: implicitHeight

            implicitHeight: 36
            color: "#cc1a1a2e" // semi-transparent dark background

            // RowLayout arranges children horizontally.
            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 12
                }

                // Left section: a simple label.
                Text {
                    text: "Quickshell Demo"
                    color: "#89b4fa" // blue-ish accent
                    font {
                        family: "monospace"
                        pixelSize: 14
                        bold: true
                    }
                }

                // Middle section: spacer that pushes widgets to edges.
                Item {
                    Layout.fillWidth: true
                }

                // Right section: volume and clock.
                RowLayout {
                    spacing: 16

                    VolumeWidget {}
                    ClockWidget {}
                }
            }
        }
    }
}
