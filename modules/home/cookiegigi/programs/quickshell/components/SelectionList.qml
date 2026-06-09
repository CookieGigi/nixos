import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../theme"

// Reusable keyboard-navigable list.
// Items must be normalized to: { label: string } unless a custom itemDelegate is used.
//
// Key handling:
//   - Up / Down    : change currentIndex (incrementCurrent / decrementCurrent)
//   - Enter/Return : activateCurrent()
//   - Mouse hover  : sets currentIndex
//   - Mouse click  : activates item
//
// Parent should connect PopupKeyController signals in Component.onCompleted.
ListView {
    id: root

    // Normalized items: array of objects with at least `.label` and optionally `.icon`
    // Ignored when model is set directly.
    property var items: []

    // Whether Up/Down navigation wraps around at the ends.
    property bool wrapNavigation: false

    // Custom delegate. If not set, uses the default text+icon delegate.
    property Component itemDelegate: defaultDelegate

    signal itemActivated(int index)
    signal escapePressed

    clip: true
    spacing: 2
    model: items
    delegate: itemDelegate
    currentIndex: -1

    function incrementCurrent() {
        if (root.count === 0)
            return;
        if (root.wrapNavigation) {
            root.currentIndex = (root.currentIndex + 1) % root.count;
        } else {
            root.currentIndex = Math.min(root.currentIndex + 1, root.count - 1);
        }
        root.positionViewAtIndex(root.currentIndex, ListView.Center);
    }

    function decrementCurrent() {
        if (root.count === 0)
            return;
        if (root.wrapNavigation) {
            root.currentIndex = root.currentIndex > 0 ? root.currentIndex - 1 : root.count - 1;
        } else {
            root.currentIndex = Math.max(root.currentIndex - 1, 0);
        }
        root.positionViewAtIndex(root.currentIndex, ListView.Center);
    }

    function activateCurrent() {
        if (root.currentIndex >= 0 && root.currentIndex < root.count) {
            root.itemActivated(root.currentIndex);
        }
    }

    Component {
        id: defaultDelegate
        Rectangle {
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
}
