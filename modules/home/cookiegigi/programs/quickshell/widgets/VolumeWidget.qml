import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"
import "../components"

// Volume widget: shows the current Pipewire sink volume as a percentage.
Percentage {
    icon: "\ud83d\udd0a"
    value: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%"
}
