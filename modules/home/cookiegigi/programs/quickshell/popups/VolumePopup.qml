import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../components"
import "../theme"

PopupBase {
    id: root
    title: "Volume"
    popupId: "volume"
    popupWidth: 250

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    content: ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 12

        // Volume slider track
        Rectangle {
            id: track
            Layout.fillWidth: true
            height: 20
            radius: 10
            color: Theme.surface0

            Rectangle {
                id: fill
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
                radius: 10
                color: Theme.accentColor
            }

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => {
                    const ratio = Math.max(0, Math.min(1, mouse.x / track.width));
                    if (Pipewire.defaultAudioSink) {
                        Pipewire.defaultAudioSink.audio.volume = ratio;
                    }
                }
                onPositionChanged: mouse => {
                    if (pressed && mouse.x >= 0 && mouse.x <= track.width) {
                        const ratio = Math.max(0, Math.min(1, mouse.x / track.width));
                        if (Pipewire.defaultAudioSink) {
                            Pipewire.defaultAudioSink.audio.volume = ratio;
                        }
                    }
                }
            }
        }

        Button {
            id: muteBtn
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 80
            implicitHeight: 32
            onClicked: {
                if (Pipewire.defaultAudioSink) {
                    Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
                }
            }

            StyledText {
                anchors.centerIn: parent
                text: Pipewire.defaultAudioSink?.audio.muted ? "Unmute" : "Mute"
                color: muteBtn.isHover ? Theme.accentColor : Theme.text
            }
        }
    }
}
