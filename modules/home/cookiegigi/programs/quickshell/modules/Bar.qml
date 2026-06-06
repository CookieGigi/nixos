import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "../widgets"
import "../popups"
import "../models"

// Per-monitor bar: transparent top panel with pill widgets.
// Each monitor gets its own instance via Variants.
Scope {
    id: root

    required property var modelData

    VisibilitiesState {
        id: _visibilities
    }
    property var visibilities: _visibilities

    Component.onCompleted: {
        Visibilities.register(modelData, visibilities);
    }

    PanelWindow {
        id: barWindow
        screen: modelData

        WlrLayershell.keyboardFocus: root.visibilities.isOpen("launcher") ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
            anchorWidget: titleWidget
            alignment: "center"
        }

        PowerMenu {
            visibilities: root.visibilities
            screen: modelData
            anchorWidget: powerWidget
            alignment: "right"
        }

        NetworkMenu {
            visibilities: root.visibilities
            screen: modelData
            anchorWidget: networkWidget
            alignment: "center"
        }
        Item {
            id: barRow
            anchors {
                fill: parent
                leftMargin: 16
                rightMargin: 16
            }

            // Left: clock
            RowLayout {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }
                spacing: 8
                ClockWidget {
                    Layout.fillHeight: true
                }
            }

            // Center: window title (clickable → launcher, or search input when open)
            WindowTitleWidget {
                id: titleWidget
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

                MusicWidget {
                    Layout.fillHeight: true
                }
                VolumeWidget {
                    Layout.fillHeight: true
                }
                NetworkWidget {
                    id: networkWidget
                    screen: modelData
                    Layout.fillHeight: true
                }
                BatteryWidget {
                    Layout.fillHeight: true
                }
                PowerWidget {
                    id: powerWidget
                    screen: modelData
                    Layout.fillHeight: true
                }
            }
        }
    }
}
