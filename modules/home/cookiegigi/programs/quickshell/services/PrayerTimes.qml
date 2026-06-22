pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io

// Prayer times singleton.
// Runs `prayer-times-json` at startup and daily at 00:01,
// then re-evaluates next prayer every minute.
Singleton {
    id: root

    // ── Public API ────────────────────────────────────────
    readonly property bool ready: _ready
    readonly property string nextPrayerName: _nextPrayerName
    readonly property string nextPrayerTime: _nextPrayerTime
    readonly property var prayers: _prayers
    readonly property string hijriDate: _hijriDate
    readonly property string hijriWeekday: _hijriWeekday

    // ── Backing props ─────────────────────────────────────
    property bool _ready: false
    property string _nextPrayerName: ""
    property string _nextPrayerTime: ""
    property var _prayers: []
    property string _hijriDate: ""
    property string _hijriWeekday: ""
    property var _prayerOrder: ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]

    // ── Data fetcher ──────────────────────────────────────
    property var _fetchProcess: Process {
        id: fetchProcess
        command: ["prayer-times-json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root._hijriDate = data.date?.hijri?.day + " " + data.date?.hijri?.month?.en + " " + data.date?.hijri?.year + " AH";
                    root._hijriWeekday = data.date?.hijri?.weekday?.en ?? "";

                    const list = [];
                    for (const name of root._prayerOrder) {
                        const iso = data[name];
                        if (iso) {
                            const d = new Date(iso);
                            list.push({
                                name: name,
                                time: Qt.formatTime(d, "hh:mm"),
                                timestamp: d.getTime()
                            });
                        }
                    }
                    root._prayers = list;
                    root._ready = true;
                    root._updateNextPrayer();
                } catch (e) {
                    console.warn("PrayerTimes: failed to parse JSON:", e);
                    root._ready = false;
                }
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("PrayerTimes: prayer-times-json exited with code", exitCode);
            }
        }
    }

    // ── Refresh triggers ──────────────────────────────────
    function refresh() {
        fetchProcess.running = true;
    }
    Component.onCompleted: root.refresh()

    // Daily refresh at 00:01
    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: {
            const now = new Date();
            if (now.getHours() === 0 && now.getMinutes() === 1) {
                root.refresh();
            }
            root._updateNextPrayer();
        }
    }

    // ── Next-prayer logic ─────────────────────────────────
    function _updateNextPrayer() {
        if (!root._ready || root._prayers.length === 0)
            return;

        const now = Date.now();
        let found = false;

        for (const p of root._prayers) {
            if (p.timestamp > now) {
                root._nextPrayerName = p.name;
                root._nextPrayerTime = p.time;
                found = true;
                break;
            }
        }

        // All prayers passed → show next day's Fajr
        if (!found) {
            root._nextPrayerName = root._prayers[0].name + " (tomorrow)";
            root._nextPrayerTime = root._prayers[0].time;
        }
    }
}
