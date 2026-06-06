import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"
import "../services"

// Center widget: shows the active window title, or a search input when
// the app launcher is active on this monitor.
Item {
    id: root

    property var screen: null
    property var visibilities: null

    property bool isLauncherOpen: visibilities ? visibilities.isOpen("launcher") : false

    implicitWidth: Math.min((root.isLauncherOpen ? 200 : (root.visibilities && root.visibilities.popupTitle !== "" ? popupTitleText.implicitWidth : titleText.implicitWidth)) + Theme.paddingH * 2, 400)
    implicitHeight: Math.max(titleText.implicitHeight, popupTitleText.implicitHeight, searchInput.implicitHeight) + Theme.paddingV * 2

    Button {
        id: bg
        anchors.fill: parent

        visible: (ToplevelManager.activeToplevel?.title ?? "") != "" || (root.visibilities ? root.visibilities.popupTitle : "") != "" || root.isLauncherOpen

        onClicked: {
            if (root.screen && !root.isLauncherOpen) {
                Visibilities.toggleLauncher(root.screen);
            }
        }

        StyledText {
            id: titleText
            visible: !root.isLauncherOpen && (!root.visibilities || root.visibilities.popupTitle === "")
            anchors.centerIn: parent
            width: parent.width - Theme.paddingH * 2
            text: ToplevelManager.activeToplevel?.title ?? ""
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            styledBold: true
            color: bg.isHover ? Theme.accentColor : Theme.text
        }

        StyledText {
            id: popupTitleText
            visible: !root.isLauncherOpen && root.visibilities && root.visibilities.popupTitle !== ""
            anchors.centerIn: parent
            width: parent.width - Theme.paddingH * 2
            text: root.visibilities ? root.visibilities.popupTitle : ""
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            styledBold: true
        }

        TextInput {
            id: searchInput
            visible: root.isLauncherOpen
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: closeBtn.left
                leftMargin: Theme.paddingH
                rightMargin: 4
            }
            text: visibilities ? visibilities.launcherFilter : ""
            color: Theme.text
            font {
                family: Theme.fontFamily
                pixelSize: Theme.pixelSize
            }
            focus: visible
            activeFocusOnTab: true
            cursorVisible: true
            horizontalAlignment: Text.AlignHCenter

            onTextChanged: {
                if (visibilities) {
                    visibilities.launcherFilter = text;
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    if (visibilities) {
                        visibilities.close("launcher");
                        visibilities.launcherFilter = "";
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (visibilities) {
                        visibilities.launcherActivate();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    if (visibilities) {
                        visibilities.launcherIncrement();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    if (visibilities) {
                        visibilities.launcherDecrement();
                    }
                    event.accepted = true;
                }
            }

            onVisibleChanged: {
                if (visible) {
                    focusDelay.start();
                }
            }
        }

        StyledText {
            id: closeBtn
            visible: root.isLauncherOpen
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: Theme.paddingH
            }
            text: ""
            color: Theme.text

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onEntered: {
                    closeBtn.color = Theme.accentColor;
                }
                onExited: {
                    closeBtn.color = Theme.text;
                }
                onClicked: {
                    if (root.visibilities) {
                        root.visibilities.close("launcher");
                        root.visibilities.launcherFilter = "";
                    }
                }
            }
        }
    }

    Timer {
        id: focusDelay
        interval: 100
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }
}
