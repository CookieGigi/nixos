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
    property VisibilitiesState visibilities: _visibilities

    readonly property real columnWidth: barRow.width / 3 - 16

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
        FlexboxLayout {
            id: barRow
            direction: FlexboxLayout.Row
            justifyContent: FlexboxLayout.JustifySpaceBetween
            alignItems: FlexboxLayout.AlignCenter
            columnGap: 16
            anchors {
                fill: parent
                leftMargin: 16
                rightMargin: 16
            }

            // Left: clock
            FlexboxLayout {
                justifyContent: FlexboxLayout.JustifyStart
                Layout.preferredWidth: columnWidth
                Layout.maximumWidth: columnWidth
                Layout.fillHeight: true
                ClockWidget {
                    Layout.fillHeight: true
                }
            }

            // Center: window title (clickable → launcher, or search input when open)
            FlexboxLayout {
                justifyContent: FlexboxLayout.JustifyCenter
                Layout.preferredWidth: columnWidth
                Layout.maximumWidth: columnWidth
                Layout.fillHeight: true
                WindowTitleWidget {
                    id: titleWidget
                    Layout.fillHeight: true
                    screen: modelData
                    visibilities: root.visibilities
                }
            }

            // Right: system info widgets
            FlexboxLayout {
                id: rightLayout
                columnGap: 8
                justifyContent: FlexboxLayout.JustifyEnd
                clip: true
                Layout.maximumWidth: columnWidth
                Layout.preferredWidth: columnWidth
                Layout.fillHeight: true

                MusicWidget {
                    Layout.fillWidth: true
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
