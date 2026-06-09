pragma Singleton
import Quickshell
import QtQuick

// A singleton that provides the current system time.
Singleton {
    id: root

    readonly property string time: Qt.formatDateTime(clock.date, "ddd d MMM hh:mm")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
