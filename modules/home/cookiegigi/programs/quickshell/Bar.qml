import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// A top panel bar that appears on every connected monitor.
// Fully transparent background; each widget lives in its own
// rounded pill container.
Scope {
    id: root

    property color containerBg: "#b324273a"
    property int containerRadius: 8
    property int containerPaddingV: 6
    property int containerPaddingH: 12

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            exclusiveZone: implicitHeight
            implicitHeight: 36
            color: "transparent"

            // Allow transparency
            surfaceFormat.opaque: false

            RowLayout {
                id: barRow
                anchors {
                    fill: parent
                    leftMargin: 16
                    rightMargin: 16
                }

                // Left: time in rounded container
                Rectangle {
                    radius: root.containerRadius
                    color: root.containerBg
                    Layout.preferredHeight: timeText.implicitHeight + root.containerPaddingV * 2
                    Layout.preferredWidth: timeText.implicitWidth + root.containerPaddingH * 2

                    Text {
                        id: timeText
                        anchors.centerIn: parent
                        text: Time.time
                        color: "#8bd5ca"
                        font {
                            family: "monospace"
                            pixelSize: 14
                            bold: true
                        }
                    }
                }

                // Spacer
                Item {
                    Layout.fillWidth: true
                }

                // Center: window title in rounded container
                Rectangle {
                    radius: root.containerRadius
                    color: root.containerBg
                    Layout.preferredHeight: titleText.implicitHeight + root.containerPaddingV * 2
                    Layout.preferredWidth: titleText.implicitWidth + root.containerPaddingH * 2
                    Layout.maximumWidth: barRow.width * 0.4

                    Text {
                        id: titleText
                        anchors.centerIn: parent
                        width: parent.width - root.containerPaddingH * 2
                        text: ToplevelManager.activeToplevel?.title ?? ""
                        color: "#8bd5ca"
                        font {
                            family: "monospace"
                            pixelSize: 14
                        }
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Spacer
                Item {
                    Layout.fillWidth: true
                }

                // Right: battery + power button (each brings its own container)
                RowLayout {
                    spacing: 8

                    BatteryWidget {}
                    PowerButton {}
                }
            }
        }
    }
}
