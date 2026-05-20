pragma Singleton
import Quickshell
import QtQuick

// A singleton that provides the current system time.
// Singletons have only one instance and are accessible from any scope.
Singleton {
    id: root

    // Qt.formatDateTime formats a Date object into a string.
    // This format shows: "Wed May 20 03:45:30 PM EDT 2026"
    readonly property string time: Qt.formatDateTime(
        clock.date,
        "ddd MMM d hh:mm:ss AP t yyyy"
    )

    // SystemClock is a built-in Quickshell type that exposes system time.
    // Setting precision to Seconds ensures the binding updates every second.
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
