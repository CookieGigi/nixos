import QtQuick
import "../theme"
import "../components"
import "../services"

// Clock widget: a pill displaying the current time.
Pill {
    property var screen: null

    implicitWidth: timeText.implicitWidth + Theme.paddingH * 2
    implicitHeight: timeText.implicitHeight + Theme.paddingV * 2

    StyledText {
        id: timeText
        anchors.centerIn: parent
        text: Time.time
        styledBold: true
    }

    onClicked: {
        if (screen) {
            PopupRegistry.toggleCalendar(screen);
        }
    }
}
