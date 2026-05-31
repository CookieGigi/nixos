import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

// Pill containing an icon + percentage value.
// Used by VolumeWidget and BatteryWidget.
Pill {
    id: root

    property string icon: ""
    property string value: ""
    property color accentColor: Theme.text

    implicitWidth: layout.implicitWidth + Theme.paddingH * 2
    implicitHeight: layout.implicitHeight + Theme.paddingV * 2

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6

        Icon {
            text: root.icon
        }

        StyledText {
            text: root.value
            styledBold: true
            color: root.accentColor
        }
    }
}
