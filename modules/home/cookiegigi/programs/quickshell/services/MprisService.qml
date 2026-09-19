pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// MprisService — singleton wrapper around Quickshell.Services.Mpris.
// Exposes active players and helper methods for
// playback control, volume, seeking, loop/shuffle, and window management.
Singleton {
    id: root

    // -- Raw players from Quickshell --
    readonly property var allPlayers: Mpris.players.values

    // Identity is a display name, not a unique player identifier.
    readonly property var activePlayers: allPlayers.filter(p => p.playbackState !== MprisPlaybackState.Stopped)

    readonly property bool hasActivePlayers: activePlayers.length > 0
    readonly property var primaryPlayer: hasActivePlayers ? activePlayers[0] : null

    // -- Icon helpers --
    function playbackStateIcon(player) {
        if (!player)
            return "󰓛";
        if (player.playbackState === MprisPlaybackState.Playing)
            return "";
        if (player.playbackState === MprisPlaybackState.Paused)
            return "󰏤";
        return "󰓛";
    }

    function loopStateIcon(player) {
        if (!player || !player.loopSupported)
            return "";
        if (player.loopState === MprisLoopState.Track)
            return "󰑘";
        if (player.loopState === MprisLoopState.Playlist)
            return "󰑖";
        return "󰑗"; // None
    }

    function shuffleIcon(player) {
        if (!player || !player.shuffleSupported)
            return "";
        return player.shuffle ? "󰒟" : "󰒠";
    }

    // -- Time formatting --
    function formatTime(seconds) {
        if (typeof seconds !== "number" || !isFinite(seconds) || seconds < 0)
            return "--:--";
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        const s = Math.floor(seconds % 60);
        if (h > 0) {
            return h + ":" + (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
        }
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    // -- Playback control --
    function togglePlaying(player) {
        if (player && player.canControl && player.canTogglePlaying)
            player.togglePlaying();
    }
    function play(player) {
        if (player && player.canControl && player.canPlay)
            player.play();
    }
    function pause(player) {
        if (player && player.canControl && player.canPause)
            player.pause();
    }
    function stop(player) {
        if (player && player.canControl)
            player.stop();
    }
    function next(player) {
        if (player && player.canControl && player.canGoNext)
            player.next();
    }
    function previous(player) {
        if (player && player.canControl && player.canGoPrevious)
            player.previous();
    }

    // -- Seek / Position --
    function seek(player, offset) {
        if (player && player.canControl && player.canSeek && Number.isFinite(offset))
            player.seek(offset);
    }
    function setPosition(player, position) {
        if (player && player.canControl && player.canSeek && player.positionSupported && Number.isFinite(position) && position >= 0)
            player.position = position;
    }

    // -- Volume (per source!) --
    // Keep volume state with each player delegate, avoiding Qt's WeakMap crash.
    // Watch stopped players too, and discard state when a player disconnects.
    Variants {
        id: volumeWatchers
        model: root.allPlayers
        delegate: Connections {
            required property var modelData
            property real lastVolume: 0.5
            target: modelData

            function rememberVolume() {
                if (modelData && modelData.volumeSupported && Number.isFinite(modelData.volume) && modelData.volume > 0)
                    lastVolume = modelData.volume;
            }

            function onVolumeChanged() {
                rememberVolume();
            }
            Component.onCompleted: rememberVolume()
        }
    }

    function setVolume(player, volume) {
        if (player && player.canControl && player.volumeSupported && Number.isFinite(volume)) {
            player.volume = Math.max(0.0, Math.min(1.0, volume));
        }
    }

    function toggleMute(player) {
        if (!player || !player.canControl || !player.volumeSupported)
            return;
        const watcher = volumeWatchers.instances.find(instance => instance.modelData === player);
        player.volume = player.volume > 0 ? 0 : (watcher ? watcher.lastVolume : 0.5);
    }

    // -- Loop / Shuffle --
    function setLoopState(player, state) {
        if (player && player.loopSupported && player.canControl)
            player.loopState = state;
    }
    function cycleLoopState(player) {
        if (!player || !player.loopSupported || !player.canControl)
            return;
        if (player.loopState === MprisLoopState.None)
            player.loopState = MprisLoopState.Track;
        else if (player.loopState === MprisLoopState.Track)
            player.loopState = MprisLoopState.Playlist;
        else
            player.loopState = MprisLoopState.None;
    }
    function setShuffle(player, enabled) {
        if (player && player.shuffleSupported && player.canControl)
            player.shuffle = enabled;
    }
    function toggleShuffle(player) {
        if (player && player.shuffleSupported && player.canControl)
            player.shuffle = !player.shuffle;
    }

    // -- Window / Player management --
    function raise(player) {
        if (player && player.canRaise)
            player.raise();
    }
    function quit(player) {
        if (player && player.canQuit)
            player.quit();
    }
}
