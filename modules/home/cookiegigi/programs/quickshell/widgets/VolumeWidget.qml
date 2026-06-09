import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"
import "../components"
import "../services"

// Volume widget: shows the current Pipewire sink volume as a percentage.
Percentage {
    id: root

    property var screen: null

    // Bind the default audio sink so volume/mute properties are available.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    icon: Pipewire.defaultAudioSink?.audio.muted ? "󰝟" : ""
    value: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%"

    onClicked: {
        if (screen) {
            PopupRegistry.toggleVolume(screen);
        }
    }
}
