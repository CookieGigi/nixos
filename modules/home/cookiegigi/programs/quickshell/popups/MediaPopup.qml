import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../components"
import "../theme"
import "../services"

// Media popup: lists all active MPRIS players with full controls.
// Volume per source, progress/seek, prev/next, loop/shuffle, album art.
PopupBase {
    id: root
    title: "Media"
    popupId: "media"
    popupWidth: 340

    // Card height ~126px + 8px spacing between cards
    implicitHeight: MprisService.activePlayers.length === 0 ? 80 : Math.min(3, MprisService.activePlayers.length) * 126 + (Math.min(3, MprisService.activePlayers.length) - 1) * 8 + 24

    content: ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 8

        // No players message
        StyledText {
            visible: MprisService.activePlayers.length === 0
            text: "No active players"
            Layout.alignment: Qt.AlignHCenter
            color: Theme.overlay1
        }

        // Scrollable list of active MPRIS players (max 3 visible by default)
        SelectionList {
            id: playerList
            Layout.fillWidth: true
            Layout.fillHeight: true
            wrapNavigation: true
            items: MprisService.activePlayers
            spacing: 8

            itemDelegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool isCurrent: ListView.isCurrentItem
                readonly property var player: modelData
                property real currentPosition: player.position
                property real currentVolume: player.volume

                width: parent.width
                implicitHeight: cardContent.implicitHeight + 16
                color: isCurrent ? Theme.popupItemHover : "transparent"
                radius: 6

                ColumnLayout {
                    id: cardContent
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    spacing: 6

                    // -- Top row: art + track info --
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Album art (click to raise player)
                        Rectangle {
                            implicitWidth: 44
                            implicitHeight: 44
                            radius: 4
                            color: Theme.surface0
                            visible: player.trackArtUrl !== ""

                            Image {
                                anchors.fill: parent
                                source: player.trackArtUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: MprisService.raise(player)
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: player.trackTitle || "Unknown Track"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                styledBold: true
                                color: isCurrent ? Theme.accentColor : Theme.text
                            }

                            StyledText {
                                text: (player.trackArtist || "") + (player.trackAlbumArtist && player.trackAlbumArtist !== player.trackArtist ? " — " + player.trackAlbumArtist : "")
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                styledSize: 12
                                color: Theme.overlay1
                            }

                            StyledText {
                                text: player.identity || ""
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                styledSize: 10
                                color: Theme.overlay0
                            }
                        }
                    }

                    // -- Progress bar (seekable) --
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: player.lengthSupported && player.positionSupported

                        StyledText {
                            text: MprisService.formatTime(parent.parent.parent.currentPosition)
                            styledSize: 10
                            color: Theme.overlay0
                        }

                        Rectangle {
                            id: progressTrack
                            Layout.fillWidth: true
                            implicitHeight: 6
                            radius: 3
                            color: Theme.surface0

                            Rectangle {
                                id: progressFill
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: player.length > 0 ? parent.width * (parent.parent.parent.parent.currentPosition / player.length) : 0
                                radius: 3
                                color: Theme.accentColor
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: mouse => {
                                    if (player.length > 0) {
                                        const ratio = Math.max(0, Math.min(1, mouse.x / progressTrack.width));
                                        MprisService.setPosition(player, ratio * player.length);
                                    }
                                }
                                onPositionChanged: mouse => {
                                    if (pressed && player.length > 0 && mouse.x >= 0 && mouse.x <= progressTrack.width) {
                                        const ratio = Math.max(0, Math.min(1, mouse.x / progressTrack.width));
                                        MprisService.setPosition(player, ratio * player.length);
                                    }
                                }
                            }
                        }

                        StyledText {
                            text: MprisService.formatTime(player.length)
                            styledSize: 10
                            color: Theme.overlay0
                        }
                    }

                    // -- Controls row: prev / play-pause / next / volume --
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Prev
                        Button {
                            implicitWidth: 28
                            implicitHeight: 28
                            visible: player.canGoPrevious
                            onClicked: MprisService.previous(player)

                            Icon {
                                anchors.centerIn: parent
                                text: "󰒮"
                                iconSize: 12
                                accentColor: parent.isHover ? Theme.accentColor : Theme.text
                            }
                        }

                        // Play / Pause
                        Button {
                            implicitWidth: 32
                            implicitHeight: 32
                            onClicked: MprisService.togglePlaying(player)

                            Icon {
                                anchors.centerIn: parent
                                text: player.playbackState === MprisPlaybackState.Playing ? "󰏤" : ""
                                iconSize: 14
                                accentColor: parent.isHover ? Theme.accentColor : Theme.text
                            }
                        }

                        // Next
                        Button {
                            implicitWidth: 28
                            implicitHeight: 28
                            visible: player.canGoNext
                            onClicked: MprisService.next(player)

                            Icon {
                                anchors.centerIn: parent
                                text: "󰒭"
                                iconSize: 12
                                accentColor: parent.isHover ? Theme.accentColor : Theme.text
                            }
                        }

                        // Loop state toggle
                        Button {
                            implicitWidth: 28
                            implicitHeight: 28
                            visible: player.loopSupported
                            onClicked: MprisService.cycleLoopState(player)

                            Icon {
                                anchors.centerIn: parent
                                text: MprisService.loopStateIcon(player)
                                iconSize: 12
                                accentColor: player.loopState !== MprisLoopState.None ? Theme.accentColor : (parent.isHover ? Theme.accentColor : Theme.overlay0)
                            }
                        }

                        // Shuffle toggle
                        Button {
                            implicitWidth: 28
                            implicitHeight: 28
                            visible: player.shuffleSupported
                            onClicked: MprisService.toggleShuffle(player)

                            Icon {
                                anchors.centerIn: parent
                                text: MprisService.shuffleIcon(player)
                                iconSize: 12
                                accentColor: player.shuffle ? Theme.accentColor : (parent.isHover ? Theme.accentColor : Theme.overlay0)
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        } // spacer

                        // Volume slider
                        Rectangle {
                            id: volTrack
                            implicitWidth: 70
                            implicitHeight: 6
                            radius: 3
                            color: Theme.surface0

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: parent.width * parent.parent.parent.parent.currentVolume
                                radius: 3
                                color: Theme.accentColor
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: mouse => {
                                    const ratio = Math.max(0, Math.min(1, mouse.x / volTrack.width));
                                    MprisService.setVolume(player, ratio);
                                }
                                onPositionChanged: mouse => {
                                    if (pressed && mouse.x >= 0 && mouse.x <= volTrack.width) {
                                        const ratio = Math.max(0, Math.min(1, mouse.x / volTrack.width));
                                        MprisService.setVolume(player, ratio);
                                    }
                                }
                            }
                        }
                    }
                }

                Timer {
                    interval: 1000
                    running: player && player.playbackState === MprisPlaybackState.Playing
                    repeat: true
                    onTriggered: {
                        if (player) {
                            parent.currentPosition = player.position;
                            parent.currentVolume = player.volume;
                        }
                    }
                }

                // Hover and click handling for list selection.
                // Placed at z: -1 so the ColumnLayout's children (buttons, sliders)
                // receive their own mouse events first; we only handle clicks on
                // non-interactive areas (text, margins) and hover highlighting.
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    hoverEnabled: true
                    onEntered: {
                        if (index !== playerList.currentIndex) {
                            parent.color = Theme.popupItemHover;
                        }
                    }
                    onExited: {
                        if (index !== playerList.currentIndex) {
                            parent.color = "transparent";
                        }
                    }
                    onClicked: {
                        playerList.currentIndex = index;
                    }
                }
            }

            onItemActivated: index => {
                if (index >= 0 && index < MprisService.activePlayers.length) {
                    MprisService.togglePlaying(MprisService.activePlayers[index]);
                }
            }

            onEscapePressed: root.closePopup()
        }
    }

    onOpened: {
        if (MprisService.activePlayers.length > 0) {
            playerList.currentIndex = 0;
        } else {
            playerList.currentIndex = -1;
        }
    }

    onClosing: {
        playerList.currentIndex = -1;
    }

    // Wire PopupKeyController signals to drive SelectionList
    Component.onCompleted: {
        controller.navigateUp.connect(playerList.decrementCurrent);
        controller.navigateDown.connect(playerList.incrementCurrent);
        controller.activate.connect(playerList.activateCurrent);
    }

    // Global media key handler for the selected player.
    // Up/Down/Enter/Escape are handled by PopupKeyController; everything else
    // falls through to PopupBase.unhandledKeyPressed.
    onUnhandledKeyPressed: event => {
        if (playerList.currentIndex < 0)
            return;
        const player = MprisService.activePlayers[playerList.currentIndex];
        if (!player)
            return;

        if (event.key === Qt.Key_Left) {
            if (player.canSeek) {
                MprisService.seek(player, -10);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Right) {
            if (player.canSeek) {
                MprisService.seek(player, 10);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
            if (player.canControl) {
                MprisService.setVolume(player, player.volume + 0.05);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Minus) {
            if (player.canControl) {
                MprisService.setVolume(player, player.volume - 0.05);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_N) {
            if (player.canGoNext) {
                MprisService.next(player);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_P) {
            if (player.canGoPrevious) {
                MprisService.previous(player);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_L) {
            if (player.loopSupported) {
                MprisService.cycleLoopState(player);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_S) {
            if (player.shuffleSupported) {
                MprisService.toggleShuffle(player);
                event.accepted = true;
            }
        }
    }
}
