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
    property var popups: []  // Array of popup instances passed from Bar.qml

    // Find the active popup (isOpen === true) from the popups array
    property var activePopup: {
        for (let i = 0; i < popups.length; i++) {
            if (popups[i].isOpen)
                return popups[i];
        }
        return null;
    }

    property bool isLauncherOpen: {
        for (let i = 0; i < popups.length; i++) {
            if (popups[i].popupId === "launcher" && popups[i].isOpen)
                return true;
        }
        return false;
    }

    property string popupTitle: PopupRegistry.getActivePopupTitle(screen)

    implicitWidth: Math.min((root.isLauncherOpen ? 200 : (root.popupTitle !== "" ? popupTitleText.implicitWidth : titleText.implicitWidth)) + Theme.paddingH * 2, 400)
    implicitHeight: Math.max(titleText.implicitHeight, popupTitleText.implicitHeight, searchInput.implicitHeight) + Theme.paddingV * 2

    Button {
        id: bg
        anchors.fill: parent

        visible: (ToplevelManager.activeToplevel?.title ?? "") != "" || root.popupTitle !== "" || root.isLauncherOpen

        onClicked: {
            if (root.screen && !root.isLauncherOpen) {
                PopupRegistry.toggleLauncher(root.screen);
            }
        }

        StyledText {
            id: titleText
            visible: !root.isLauncherOpen && root.popupTitle === ""
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
            visible: !root.isLauncherOpen && root.popupTitle !== ""
            anchors.centerIn: parent
            width: parent.width - Theme.paddingH * 2
            text: root.popupTitle
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
            text: root.activePopup ? root.activePopup.controller.searchText : ""
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
                if (root.activePopup && root.activePopup.controller.searchText !== text) {
                    root.activePopup.controller.searchText = text;
                }
            }

            // No Keys.onPressed here — keyboard is handled by the popup's hidden
            // TextInput and PopupKeyController. This TextInput is display-only.
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
                    PopupRegistry.closeAll(root.screen);
                    if (root.activePopup) {
                        root.activePopup.controller.searchText = "";
                    }
                }
            }
        }
    }
}
