import QtQuick
import "../theme"

// Styled background pill. Widgets that extend this must set their own
// implicitWidth / implicitHeight based on their content + Theme padding.
Rectangle {
    id: root

    property int paddingV: Theme.paddingV
    property int paddingH: Theme.paddingH

    property bool isHover: false

    topLeftRadius: 0
    topRightRadius: 0
    bottomLeftRadius: Theme.containerRadius
    bottomRightRadius: Theme.containerRadius
    color: Theme.containerAlpha

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            isHover = true;
        }
        onExited: {
            isHover = false;
        }
    }
}
