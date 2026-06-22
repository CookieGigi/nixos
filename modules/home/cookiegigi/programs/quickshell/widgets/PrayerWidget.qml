import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"
import "../services"

// Prayer widget: shows the next prayer name and time.
Pill {
    id: root

    property var screen: null

    visible: PrayerTimes.ready
    implicitWidth: prayerLayout.implicitWidth + Theme.paddingH * 2
    implicitHeight: prayerLayout.implicitHeight + Theme.paddingV * 2

    RowLayout {
        id: prayerLayout
        anchors.centerIn: parent
        spacing: 6

        Icon {
            text: "🕌"
            accentColor: root.isHover ? Theme.accentColor : Theme.text
        }

        StyledText {
            text: PrayerTimes.nextPrayerName + " " + PrayerTimes.nextPrayerTime
            styledBold: true
        }
    }

    onClicked: {
        if (screen) {
            PopupRegistry.togglePrayer(screen);
        }
    }
}
