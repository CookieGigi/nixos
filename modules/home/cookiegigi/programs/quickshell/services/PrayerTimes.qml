pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io

// Prayer times singleton.
// Runs `prayer-times-json` at startup and when its schedule date is stale,
// checking the date and next prayer every minute (including after suspend).
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
    property string _loadedDate: ""
    property string _tomorrowFajrTime: ""
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
                    if (data.calculationDate !== Qt.formatDate(new Date(), "yyyy-MM-dd"))
                        throw new Error("stale schedule date");

                    const list = [];
                    for (const name of root._prayerOrder) {
                        const d = new Date(data[name]);
                        if (!data[name] || !Number.isFinite(d.getTime()))
                            throw new Error("invalid prayer time: " + name);
                        list.push({
                            name: name,
                            time: Qt.formatTime(d, "hh:mm"),
                            timestamp: d.getTime()
                        });
                    }
                    const tomorrow = new Date(data.tomorrowFajr);
                    if (!data.tomorrowFajr || !Number.isFinite(tomorrow.getTime()) || tomorrow.getTime() <= list[list.length - 1].timestamp)
                        throw new Error("invalid tomorrow Fajr");

                    root._hijriDate = data.date?.hijri?.day + " " + data.date?.hijri?.month?.en + " " + data.date?.hijri?.year + " AH";
                    root._hijriWeekday = data.date?.hijri?.weekday?.en ?? "";
                    root._prayers = list;
                    root._tomorrowFajrTime = Qt.formatTime(tomorrow, "hh:mm");
                    root._loadedDate = data.calculationDate;
                    root._ready = true;
                    root._updateNextPrayer();
                } catch (e) {
                    console.warn("PrayerTimes: failed to parse JSON:", e);
                    root._ready = false;
                    root._updateNextPrayer();
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
        if (!fetchProcess.running)
            fetchProcess.running = true;
    }
    Component.onCompleted: root.refresh()

    // Retry failed fetches, and do not depend on observing a specific minute.
    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: {
            root._updateNextPrayer();
            if (!root._ready)
                root.refresh();
        }
    }

    // ── Next-prayer logic ─────────────────────────────────
    function _updateNextPrayer() {
        if (root._loadedDate !== Qt.formatDate(new Date(), "yyyy-MM-dd"))
            root._ready = false;
        if (!root._ready || root._prayers.length === 0) {
            root._nextPrayerName = "";
            root._nextPrayerTime = "";
            return;
        }

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

        // All prayers passed: use the separately calculated next day's Fajr.
        if (!found) {
            root._nextPrayerName = "Fajr (tomorrow)";
            root._nextPrayerTime = root._tomorrowFajrTime;
        }
    }
}
