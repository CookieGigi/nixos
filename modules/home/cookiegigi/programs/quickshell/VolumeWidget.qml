import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

// A widget that shows the system volume using Pipewire.
// Only visible when Pipewire is available.
RowLayout {
    spacing: 6

    // Unicode speaker icon - works without any icon theme.
    Text {
        text: "\ud83d\udd0a"  // Unicode speaker icon
        color: "#ffffff"
        font.pixelSize: 14
    }

    Text {
        // Pipewire.defaultAudioSink is a built-in Quickshell integration.
        // The audio.volume is a normalized value between 0 and 1.
        text: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%"
        color: "#ffffff"
        font {
            family: "monospace"
            pixelSize: 14
        }
    }
}
