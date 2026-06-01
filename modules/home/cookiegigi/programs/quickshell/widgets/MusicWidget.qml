import QtQuick
import "../theme"
import "../components"
import QtQuick.Layouts
import Quickshell.Services.Mpris

Button {
    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    visible: player != null && player.playbackState != MprisPlaybackState.Stopping

    implicitWidth: musicText.implicitWidth + Theme.paddingH * 2
    implicitHeight: musicText.implicitHeight + Theme.paddingV * 2

    RowLayout {
        anchors.centerIn: parent
        spacing: 6
        Icon {
            text: player != null && player.playbackState == MprisPlaybackState.Playing ? "" : (player && player.playbackState == MprisPlaybackState.Paused ? "󰏤" : "󰓛")
        }

        StyledText {
            id: musicText
            text: player != null ? (player.trackTitle != "" ? player.trackTitle : player.identity) : "no music"
        }
    }

    onClicked: {
        if (player != null) {
            player.togglePlaying();
        }
    }
}
