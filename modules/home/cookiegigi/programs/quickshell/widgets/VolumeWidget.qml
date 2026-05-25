import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"
import "../components"

// Volume widget: shows the current Pipewire sink volume as a percentage.
Percentage {
    id: root

    // Bind the default audio sink so volume/mute properties are available.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    icon: Pipewire.defaultAudioSink?.audio.muted ? "\ud83d\udd07" : "\ud83d\udd0a"
    value: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%"
}
