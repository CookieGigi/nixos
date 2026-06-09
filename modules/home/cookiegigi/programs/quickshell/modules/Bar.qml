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

    readonly property real columnWidth: barRow.width / 3 - 16

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
            id: appLauncher
            screen: modelData
            anchorWidget: titleWidget
            alignment: "center"
        }

        PowerMenu {
            id: powerMenu
            screen: modelData
            anchorWidget: powerWidget
            alignment: "right"
        }

        NetworkMenu {
            id: networkMenu
            screen: modelData
            anchorWidget: networkWidget
            alignment: "center"
        }

        CalendarPopup {
            id: calendarPopup
            screen: modelData
            anchorWidget: clockWidget
            alignment: "left"
        }

        MediaPopup {
            id: mediaPopup
            screen: modelData
            anchorWidget: mediaWidget
            alignment: "center"
        }

        VolumePopup {
            id: volumePopup
            screen: modelData
            anchorWidget: volumeWidget
            alignment: "center"
        }

        BatteryPopup {
            id: batteryPopup
            screen: modelData
            anchorWidget: batteryWidget
            alignment: "right"
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
                    id: clockWidget
                    Layout.fillHeight: true
                    screen: modelData
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

                MediaWidget {
                    id: mediaWidget
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    screen: modelData
                }
                VolumeWidget {
                    id: volumeWidget
                    Layout.fillHeight: true
                    screen: modelData
                }
                NetworkWidget {
                    id: networkWidget
                    screen: modelData
                    Layout.fillHeight: true
                }
                BatteryWidget {
                    id: batteryWidget
                    Layout.fillHeight: true
                    screen: modelData
                }
                PowerWidget {
                    id: powerWidget
                    screen: modelData
                    Layout.fillHeight: true
                }
            }
        }
    }

    Component.onCompleted: {
        PopupRegistry.register(modelData, "launcher", appLauncher);
        PopupRegistry.register(modelData, "power", powerMenu);
        PopupRegistry.register(modelData, "network", networkMenu);
        PopupRegistry.register(modelData, "calendar", calendarPopup);
        PopupRegistry.register(modelData, "media", mediaPopup);
        PopupRegistry.register(modelData, "volume", volumePopup);
        PopupRegistry.register(modelData, "battery", batteryPopup);
    }
}
