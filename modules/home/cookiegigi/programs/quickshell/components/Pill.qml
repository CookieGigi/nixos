import QtQuick
import "../theme"

// Styled background pill. Widgets that extend this must set their own
// implicitWidth / implicitHeight based on their content + Theme padding.
Rectangle {
    id: root

    property int paddingV: Theme.paddingV
    property int paddingH: Theme.paddingH

    radius: Theme.containerRadius
    color: Theme.containerAlpha
}
