import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../theme"

// Reusable keyboard-navigable list.
// Items must be normalized to: { label: string }
//
// Key handling:
//   - Up / Down    : change currentIndex
//   - Enter/Return : activateCurrent()
//   - Mouse hover  : sets currentIndex
//   - Mouse click  : activates item
//
// Parent should assign focus: true to this component so keys work.
ListView {
    id: root

    // Normalized items: array of objects with at least `.label` and optionnaly `.icon`
    property var items: []

    signal itemActivated(int index)
    signal escapePressed

    anchors.fill: parent
    anchors.margins: 10
    clip: true
    spacing: 2
    model: items
    currentIndex: -1

    function incrementCurrent() {
        if (root.count === 0)
            return;
        root.currentIndex = Math.min(root.currentIndex + 1, root.count - 1);
        root.positionViewAtIndex(root.currentIndex, ListView.Center);
    }

    function decrementCurrent() {
        if (root.count === 0)
            return;
        root.currentIndex = Math.max(root.currentIndex - 1, 0);
        root.positionViewAtIndex(root.currentIndex, ListView.Center);
    }

    function activateCurrent() {
        if (root.currentIndex >= 0 && root.currentIndex < root.count) {
            root.itemActivated(root.currentIndex);
        }
    }

    delegate: Rectangle {
        required property var modelData
        required property int index

        readonly property bool isCurrent: ListView.isCurrentItem

        width: root.width
        implicitHeight: itemLabel.implicitHeight + 14
        radius: 6
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            spacing: 6

            Icon {
                visible: isCurrent
                text: "󰅂"
                color: Theme.accentColor
            }

            IconImage {
                width: 20
                height: 20
                source: modelData.icon ? "image://icon/" + modelData.icon : ""
                visible: modelData.icon ? true : false

                Layout.fillWidth: true
                Layout.maximumWidth: 25
            }

            StyledText {
                id: itemLabel
                text: modelData.label || ""
                color: isCurrent ? Theme.accentColor : Theme.text

                Layout.fillWidth: true
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                root.currentIndex = index;
            }
            onClicked: {
                root.currentIndex = index;
                root.itemActivated(index);
            }
        }
    }
}
