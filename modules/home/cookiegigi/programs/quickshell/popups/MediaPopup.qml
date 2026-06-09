import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../components"
import "../theme"

PopupBase {
    id: root
    title: "Media"
    popupId: "media"
    popupWidth: 320
    implicitHeight: activePlayers.length === 0 ? 80 : Math.min(3, activePlayers.length) * 60 + (Math.min(3, activePlayers.length) - 1) * 8 + 24

    // Track the currently selected player index for keyboard navigation
    property int selectedIndex: -1
    property var activePlayers: {
        const seen = new Set();
        const players = Mpris.players.values.filter(p => {
            const state = p.playbackState;
            const isStopped = state === MprisPlaybackState.Stopped;
            const id = (p.identity || "").toLowerCase().replace(/[^a-z0-9]/g, "");
            if (isStopped || seen.has(id)) {
                console.log("MediaPopup skip player:", p.identity, "state:", state, "dup:", seen.has(id));
                return false;
            }
            seen.add(id);
            console.log("MediaPopup keep player:", p.identity, "desktopEntry:", p.desktopEntry, "state:", state);
            return true;
        });
        console.log("MediaPopup activePlayers count:", players.length);
        return players;
    }

    content: ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 8

        // No players message
        StyledText {
            visible: activePlayers.length === 0
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
            items: activePlayers
            spacing: 8
            anchors.margins: 0

            itemDelegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool isCurrent: ListView.isCurrentItem

                width: parent.width
                implicitHeight: playerRow.implicitHeight + 16
                color: isCurrent ? Theme.popupItemHover : "transparent"
                radius: 6

                RowLayout {
                    id: playerRow
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    spacing: 10

                    Icon {
                        visible: isCurrent
                        text: "󰅂"
                        color: Theme.accentColor
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: modelData.trackTitle || "Unknown Track"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            styledBold: true
                            color: isCurrent ? Theme.accentColor : Theme.text
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

                // Hover and click handling
                MouseArea {
                    anchors.fill: parent
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
                if (index >= 0 && index < activePlayers.length) {
                    const player = activePlayers[index];
                    console.log("MediaPopup itemActivated:", player.identity);
                    player.togglePlaying();
                }
            }

            onEscapePressed: root.closePopup()
        }
    }

    onOpened: {
        console.log("MediaPopup onOpened activePlayers:", activePlayers.length);
        for (let i = 0; i < activePlayers.length; i++) {
            const p = activePlayers[i];
            console.log("  player", i, ":", p.identity, "state:", p.playbackState);
        }
        if (activePlayers.length > 0) {
            playerList.currentIndex = 0;
        } else {
            playerList.currentIndex = -1;
        }
        console.log("MediaPopup onOpened currentIndex:", playerList.currentIndex);
    }

    onClosing: {
        console.log("MediaPopup onClosing");
        playerList.currentIndex = -1;
    }

    // Wire PopupKeyController signals to drive SelectionList
    Component.onCompleted: {
        console.log("MediaPopup Component.onCompleted wiring controller signals");
        controller.navigateUp.connect(playerList.decrementCurrent);
        controller.navigateDown.connect(playerList.incrementCurrent);
        controller.activate.connect(playerList.activateCurrent);
    }
}
