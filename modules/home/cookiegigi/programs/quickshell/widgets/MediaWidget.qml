import QtQuick
import "../theme"
import "../components"
import "../services"
import QtQuick.Layouts
import Quickshell.Services.Mpris

// Media widget: shows the primary active MPRIS player.
// Uses MprisService so all player filtering and control logic lives in one place.
Button {
    property var player: MprisService.primaryPlayer
    property var screen: null

    visible: player != null && player.playbackState != MprisPlaybackState.Stopped

    FlexboxLayout {
        id: container
        anchors.fill: parent
        anchors.leftMargin: Theme.paddingH
        anchors.rightMargin: Theme.paddingH
        anchors.topMargin: Theme.paddingV
        anchors.bottomMargin: Theme.paddingV

        columnGap: 6
        justifyContent: FlexboxLayout.JustifySpaceAround
        alignItems: FlexboxLayout.AlignCenter
        Icon {
            text: MprisService.playbackStateIcon(player)
        }

        StyledText {
            text: player != null ? (player.trackTitle != "" ? player.trackTitle : player.identity) : "no media"
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
        }
    }

    onClicked: {
        if (screen) {
            PopupRegistry.toggleMedia(screen);
        }
    }
}
