import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "components"
import "theme"

// Session-opening splash: niri spawns it alongside the bar
// (spawn-at-startup "qs" "-c" "splash"). It paints the wallpaper with a
// spinner while the session is coming up, so logging in does not sit on a
// static wallpaper waiting for the bar. The bar dismisses it over IPC
// once it has finished loading (see the Process in the bar's shell.qml);
// a Timer gives up after 12s in case the bar never loads.

ShellRoot {
    id: root

    property bool dismissing: false
    property real fade: 1

    function dismiss() {
        if (root.dismissing)
            return;
        root.dismissing = true;
        fadeOut.restart();
    }

    // Called by the bar with `qs -c splash ipc call splash dismiss`.
    IpcHandler {
        target: "splash"
        function dismiss(): void {
            root.dismiss();
        }
    }

    Timer {
        interval: 12000
        repeat: false
        running: true
        onTriggered: root.dismiss()
    }

    NumberAnimation {
        id: fadeOut
        target: root
        property: "fade"
        from: 1
        to: 0
        duration: 500
        easing.type: Easing.InOutQuad
        onFinished: Qt.quit()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            screen: window.modelData

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            surfaceFormat.opaque: false

            Item {
                anchors.fill: parent
                opacity: root.fade

                Image {
                    anchors.fill: parent
                    source: "wallpaper.jpg"
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                // Click to dismiss early (the bar is usually already up).
                MouseArea {
                    anchors.fill: parent
                    onPressed: root.dismiss()
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: spinnerColumn.implicitWidth + 64
                    height: spinnerColumn.implicitHeight + 48
                    radius: 12
                    color: "#B3000000"
                    border.width: 1
                    border.color: Theme.popupBorder

                    ColumnLayout {
                        id: spinnerColumn
                        anchors.centerIn: parent
                        spacing: 16

                        Item {
                            id: spinner

                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 56
                            implicitHeight: 56

                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                            }

                            Canvas {
                                anchors.fill: parent

                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.lineWidth = 6;
                                    ctx.lineCap = "round";
                                    ctx.strokeStyle = Theme.teal;
                                    const radius = (width - ctx.lineWidth) / 2 - 2;
                                    ctx.arc(width / 2, height / 2, radius, 0, Math.PI * 1.5);
                                    ctx.stroke();
                                }
                            }
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Starting session"
                            styledSize: 18
                            styledBold: true
                        }
                    }
                }
            }
        }
    }
}
