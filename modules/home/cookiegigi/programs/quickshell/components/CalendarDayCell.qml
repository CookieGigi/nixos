import QtQuick
import QtQuick.Layouts
import "../theme"

// A single day cell for the calendar grid.
// Handles today/selected/other-month styling and hover feedback.
Rectangle {
    id: root

    property int day: 0
    property bool isToday: false
    property bool isSelected: false
    property bool isOtherMonth: false

    signal clicked

    implicitHeight: 32
    radius: 6

    color: {
        if (root.isSelected)
            return Theme.accentColor;
        if (root.isToday)
            return Theme.surface1;
        if (hoverArea.containsMouse)
            return Theme.surface0;
        return "transparent";
    }

    StyledText {
        anchors.centerIn: parent
        text: root.day
        color: {
            if (root.isSelected)
                return Theme.base;
            if (root.isOtherMonth)
                return Theme.overlay0;
            if (root.isToday)
                return Theme.accentColor;
            return Theme.text;
        }
        styledSize: 12
        styledBold: root.isToday || root.isSelected
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
