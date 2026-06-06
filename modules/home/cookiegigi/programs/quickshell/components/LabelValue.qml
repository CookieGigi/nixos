import QtQuick.Layouts
import "../theme"

RowLayout {
    id: root
    property string label: ""
    property string value: ""

    spacing: 8
    Layout.fillWidth: true

    StyledText {
        id: labelText
        text: root.label
        color: Theme.accentColor
    }

    StyledText {
        id: valueText
        text: root.value
    }
}
