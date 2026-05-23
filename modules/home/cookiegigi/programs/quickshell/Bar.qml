import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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
            id: toplevel
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

            // App launcher popup, anchored below the center widget.
            AppLauncher {
                id: appLauncher
                anchor.window: toplevel
                anchor.rect.x: toplevel.width / 2 - width / 2
                anchor.rect.y: toplevel.height
            }

            // Power menu popup, anchored below the power button.
            PowerMenu {
                id: powerMenu
                anchor.window: toplevel
                anchor.rect.x: toplevel.width - 200 - 16
                anchor.rect.y: toplevel.height
            }

            // Poll for a trigger file created by the `show-app-launcher` script.
            Timer {
                interval: 200
                running: true
                repeat: true
                onTriggered: {
                    if (!triggerProcess.running) {
                        triggerProcess.running = true;
                    }
                }
            }

            Process {
                id: triggerProcess
                command: ["sh", "-c", "if [ -f /tmp/quickshell-launcher ]; then rm /tmp/quickshell-launcher; echo OPEN; fi"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (text.trim() === "OPEN") {
                            appLauncher.openLauncher();
                        }
                    }
                }
            }

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
                        color: "#ffffff"
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

                // Center: window title in rounded container (clickable → app launcher)
                Rectangle {
                    id: centerWidget
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
                        color: "#ffffff"
                        font {
                            family: "monospace"
                            pixelSize: 14
                        }
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appLauncher.openLauncher()
                    }
                }

                // Spacer
                Item {
                    Layout.fillWidth: true
                }

                // Right: battery + volume + power button
                RowLayout {
                    spacing: 8

                    BatteryWidget {}
                    VolumeWidget {}
                    PowerButton {
                        powerMenuRef: powerMenu
                    }
                }
            }
        }
    }
}
