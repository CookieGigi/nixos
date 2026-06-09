import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../components"
import "../theme"

PopupBase {
    id: root
    title: "Music"
    popupId: "music"
    popupWidth: 320

    content: ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 8

        // No players message
        StyledText {
            visible: Mpris.players.values.length === 0
            text: "No active players"
            Layout.alignment: Qt.AlignHCenter
            color: Theme.overlay1
        }

        // List of active MPRIS players
        Repeater {
            model: Mpris.players.values.filter(p => p.playbackState !== MprisPlaybackState.Stopping)
            delegate: Rectangle {
                required property var modelData
                width: parent.width
                implicitHeight: playerRow.implicitHeight + 16
                color: "transparent"
                radius: 6

                RowLayout {
                    id: playerRow
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: modelData.trackTitle || "Unknown Track"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            styledBold: true
                        }

                        StyledText {
                            text: modelData.artist || modelData.identity || ""
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            styledSize: 12
                            color: Theme.overlay1
                        }
                    }

                    Button {
                        implicitWidth: 32
                        implicitHeight: 32
                        onClicked: {
                            modelData.togglePlaying();
                        }

                        Icon {
                            anchors.centerIn: parent
                            text: modelData.playbackState === MprisPlaybackState.Playing ? "󰏤" : ""
                            accentColor: parent.isHover ? Theme.accentColor : Theme.text
                        }
                    }
                }

                // Hover highlight
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.color = Theme.popupItemHover
                    onExited: parent.color = "transparent"
                    // Let clicks pass through to the play/pause button
                    propagateComposedEvents: true
                }
            }
        }
    }
}
