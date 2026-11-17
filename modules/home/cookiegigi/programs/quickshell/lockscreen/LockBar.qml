import QtQuick
import QtQuick.Layouts
import Quickshell
import "widgets"
import "components"
import "theme"

// Visual-only bar for the lockscreen, mirroring modules/Bar.qml layout.
// All interactions are disabled by an overlay in LockSurface.
Item {
    id: root
    required property var screen
    readonly property alias lockTitleItem: lockTitleWidget

    implicitHeight: 36

    readonly property real columnWidth: barRow.width / 3 - 16

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

        // Left: clock + prayer + notifications
        FlexboxLayout {
            justifyContent: FlexboxLayout.JustifyStart
            columnGap: 8
            Layout.preferredWidth: root.columnWidth
            Layout.maximumWidth: root.columnWidth
            Layout.fillHeight: true

            ClockWidget {
                Layout.fillHeight: true
                screen: root.screen
            }
            PrayerWidget {
                Layout.fillHeight: true
                screen: root.screen
            }
            NotificationWidget {
                Layout.fillHeight: true
                screen: root.screen
            }
        }

        // Center: locked title (replaces launcher/window title)
        FlexboxLayout {
            justifyContent: FlexboxLayout.JustifyCenter
            Layout.preferredWidth: root.columnWidth
            Layout.maximumWidth: root.columnWidth
            Layout.fillHeight: true

            Button {
                id: lockTitleWidget
                Layout.fillHeight: true
                implicitWidth: lockedText.implicitWidth + Theme.paddingH * 2
                implicitHeight: lockedText.implicitHeight + Theme.paddingV * 2

                StyledText {
                    id: lockedText
                    anchors.centerIn: parent
                    text: "Locked"
                    styledBold: true
                    color: Theme.text
                }
            }
        }

        // Right: system info widgets
        FlexboxLayout {
            columnGap: 8
            justifyContent: FlexboxLayout.JustifyEnd
            clip: true
            Layout.preferredWidth: root.columnWidth
            Layout.maximumWidth: root.columnWidth
            Layout.fillHeight: true

            MediaWidget {
                Layout.fillWidth: true
                Layout.fillHeight: true
                screen: root.screen
            }
            VolumeWidget {
                Layout.fillHeight: true
                screen: root.screen
            }
            NetworkWidget {
                screen: root.screen
                Layout.fillHeight: true
            }
            BluetoothWidget {
                screen: root.screen
                Layout.fillHeight: true
            }
            BatteryWidget {
                Layout.fillHeight: true
                screen: root.screen
            }
            PowerWidget {
                screen: root.screen
                Layout.fillHeight: true
            }
        }
    }
}
