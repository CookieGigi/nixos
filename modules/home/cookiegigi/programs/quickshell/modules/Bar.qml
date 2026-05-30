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
        property string launcherFilter: ""
        property string popupTitle: ""

        signal launcherActivate()
        signal launcherIncrement()
        signal launcherDecrement()
    }
    property var visibilities: _visibilities

    Component.onCompleted: {
        Visibilities.register(modelData, visibilities);
    }

    PanelWindow {
        id: barWindow
        screen: modelData

        WlrLayershell.keyboardFocus: root.visibilities.launcher ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
            screen: modelData
        }

        PowerMenu {
            visibilities: root.visibilities
            screen: modelData
        }

        Item {
            id: barRow
            anchors {
                fill: parent
                leftMargin: 16
                rightMargin: 16
            }

            // Left: clock
            ClockWidget {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }
            }

            // Center: window title (clickable → launcher, or search input when open)
            WindowTitleWidget {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                screen: modelData
                visibilities: root.visibilities
            }

            // Right: system info widgets
            RowLayout {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                }
                spacing: 8

                BatteryWidget {
                    Layout.fillHeight: true
                }
                VolumeWidget {
                    Layout.fillHeight: true
                }
                NetworkWidget {
                    Layout.fillHeight: true
                }
                PowerWidget {
                    screen: modelData
                    Layout.fillHeight: true
                }
            }
        }
    }
}
