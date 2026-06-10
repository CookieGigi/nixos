pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// MprisService — singleton wrapper around Quickshell.Services.Mpris.
// Exposes filtered/deduplicated active players and helper methods for
// playback control, volume, seeking, loop/shuffle, and window management.
Singleton {
    id: root

    // -- Raw players from Quickshell --
    readonly property var allPlayers: Mpris.players.values

    // -- Filtered / deduplicated active players (not stopped) --
    readonly property var activePlayers: {
        const seen = new Set();
        const players = allPlayers.filter(p => {
            const state = p.playbackState;
            const isStopped = state === MprisPlaybackState.Stopped;
            const id = (p.identity || "").toLowerCase().replace(/[^a-z0-9]/g, "");
            if (isStopped || seen.has(id)) {
                return false;
            }
            seen.add(id);
            return true;
        });
        return players;
    }

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
        if (!seconds || !isFinite(seconds) || seconds < 0)
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
        if (player && player.canTogglePlaying)
            player.togglePlaying();
    }
    function play(player) {
        if (player && player.canPlay)
            player.play();
    }
    function pause(player) {
        if (player && player.canPause)
            player.pause();
    }
    function stop(player) {
        if (player && player.canStop)
            player.stop();
    }
    function next(player) {
        if (player && player.canGoNext)
            player.next();
    }
    function previous(player) {
        if (player && player.canGoPrevious)
            player.previous();
    }

    // -- Seek / Position --
    function seek(player, offset) {
        if (player && player.canSeek)
            player.seek(offset);
    }
    function setPosition(player, position) {
        if (player && player.canSeek && player.positionSupported)
            player.position = position;
    }

    // -- Volume (per source!) --
    function setVolume(player, volume) {
        if (player && player.canControl)
            player.volume = Math.max(0.0, Math.min(1.0, volume));
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
