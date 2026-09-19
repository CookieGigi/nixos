pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Mako remains the notification server; the center shares its live/history state.
Singleton {
    id: root

    property var active: []
    property var history: []
    property bool quiet: false
    property int openCenters: 0
    property string error: ""
    readonly property bool available: liveQuery.ok && historyQuery.ok && modeQuery.ok
    readonly property bool busy: mutation.running

    function refresh() {
        if (!liveQuery.running)
            liveQuery.running = true;
        if (!historyQuery.running)
            historyQuery.running = true;
        if (!modeQuery.running)
            modeQuery.running = true;
    }

    function run(args) {
        if (busy || !available)
            return;
        error = "";
        mutation.command = ["makoctl"].concat(args);
        mutation.running = true;
    }

    component Query: Process {
        id: query
        property bool ok: false
        property bool json: true
        signal result(var value)
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const value = query.json ? JSON.parse(text) : text.trim().split(/\s+/);
                    if (!Array.isArray(value))
                        throw new Error("Expected a list");
                    query.ok = true;
                    query.result(value);
                } catch (e) {
                    query.ok = false;
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0 || status !== 0)
                query.ok = false;
        }
    }

    Query {
        id: liveQuery
        command: ["makoctl", "list", "-j"]
        onResult: value => {
            if (JSON.stringify(root.active) !== JSON.stringify(value))
                root.active = value;
        }
    }
    Query {
        id: historyQuery
        command: ["makoctl", "history", "-j"]
        onResult: value => {
            if (JSON.stringify(root.history) !== JSON.stringify(value))
                root.history = value;
        }
    }
    Query {
        id: modeQuery
        command: ["makoctl", "mode"]
        json: false
        onResult: value => root.quiet = value.includes("do-not-disturb")
    }
    Process {
        id: mutation
        onExited: (code, status) => {
            if (code !== 0 || status !== 0)
                root.error = "Could not update notification. It may have expired.";
            root.refresh();
        }
    }
    Timer {
        interval: root.openCenters > 0 ? 1000 : 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
