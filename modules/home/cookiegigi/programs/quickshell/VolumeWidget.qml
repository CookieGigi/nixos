import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

// A widget that shows the system volume using Pipewire,
// wrapped in a rounded pill container.
Rectangle {
    id: root
    radius: 8
    color: "#b324273a"
    implicitHeight: volLayout.implicitHeight + 12
    implicitWidth: volLayout.implicitWidth + 24

    // Bind the default audio sink so volume/mute properties are available.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    RowLayout {
        id: volLayout
        anchors.centerIn: parent
        spacing: 6

        // Unicode speaker icon, muted when audio is muted.
        Text {
            text: Pipewire.defaultAudioSink?.audio.muted ? "\ud83d\udd07" : "\ud83d\udd0a"
            color: "#ffffff"
            font.pixelSize: 14
        }

        Text {
            text: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%"
            color: "#ffffff"
            font {
                family: "monospace"
                pixelSize: 14
                bold: true
            }
        }
    }
}
