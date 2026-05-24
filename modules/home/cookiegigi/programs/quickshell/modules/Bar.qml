import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "../widgets"
import "../popups"

// Per-monitor bar: transparent top panel with pill widgets.
// Each monitor gets its own instance via Variants.
Scope {
    id: root

    required property var modelData

    // Observable state object for popup visibility.
    // Using QtObject with property bool ensures QML bindings
    // re-evaluate when launcher/power are toggled.
    QtObject {
        id: _visibilities
        property bool launcher: false
        property bool power: false
    }
    property var visibilities: _visibilities

    Component.onCompleted: {
        Visibilities.register(modelData, visibilities);
    }

    PanelWindow {
        id: barWindow
        screen: modelData

        anchors {
            top: true
            left: true
            right: true
        }

        exclusiveZone: implicitHeight
        implicitHeight: 36
        color: "transparent"
        surfaceFormat.opaque: false

        // Popups
        AppLauncher {
            visibilities: root.visibilities
            anchor.window: barWindow
            anchor.rect.x: barWindow.width / 2 - width / 2
            anchor.rect.y: barWindow.height
        }

        PowerMenu {
            visibilities: root.visibilities
            anchor.window: barWindow
            anchor.rect.x: barWindow.width - width - 16
            anchor.rect.y: barWindow.height
        }

        RowLayout {
            id: barRow
            anchors {
                fill: parent
                leftMargin: 16
                rightMargin: 16
            }

            // Left: clock
            ClockWidget {}

            // Spacer
            Item {
                Layout.fillWidth: true
            }

            // Center: window title (clickable → launcher)
            WindowTitleWidget {
                screen: modelData
            }

            // Spacer
            Item {
                Layout.fillWidth: true
            }

            // Right: system info widgets
            RowLayout {
                spacing: 8

                BatteryWidget {}
                VolumeWidget {}
                NetworkWidget {}
                PowerWidget {
                    screen: modelData
                }
            }
        }
    }
}
