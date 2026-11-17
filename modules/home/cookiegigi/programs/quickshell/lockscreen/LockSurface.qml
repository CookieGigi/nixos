import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "components"
import "theme"

Rectangle {
    id: root
    required property var context
    required property var screen

    color: Theme.base

    property bool monitorsOff: false

    Process {
        id: powerOffProc
        command: ["niri", "msg", "action", "power-off-monitors"]
        onExited: root.monitorsOff = true
    }

    Process {
        id: powerOnProc
        command: ["niri", "msg", "action", "power-on-monitors"]
        onExited: root.monitorsOff = false
    }

    Timer {
        id: inactivityTimer
        interval: 30000
        repeat: false
        running: true
        onTriggered: {
            if (!root.monitorsOff) {
                powerOffProc.running = false;
                powerOffProc.running = true;
            }
        }
    }

    function registerActivity(showPrompt) {
        inactivityTimer.restart();
        if (root.monitorsOff) {
            powerOnProc.running = false;
            powerOnProc.running = true;
        }
        if (showPrompt)
            context.revealPrompt();
    }

    Image {
        anchors.fill: parent
        source: "file:///home/cookiegigi/nixos/modules/home/cookiegigi/wallpapers/voyager-4.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#40000000"
    }

    // Actual quickshell bar (visual), with all interactions disabled.
    LockBar {
        id: lockBar
        screen: root.screen
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
    }

    MouseArea {
        anchors.fill: lockBar
        acceptedButtons: Qt.AllButtons
        hoverEnabled: false
        onPressed: root.registerActivity(true)
        onClicked: root.registerActivity(true)
        onWheel: root.registerActivity(true)
    }

    // Password prompt popup below the "Locked" title, styled like PopupBase/PopupShell.
    Item {
        id: promptPopup
        visible: context.promptVisible
        z: 20
        width: popupContent.implicitWidth
        height: popupContent.implicitHeight

        readonly property point anchorPos: {
            const item = lockBar.lockTitleItem;
            if (!item)
                return Qt.point((root.width - width) / 2, lockBar.height + 15);
            // establish dependencies
            void item.x;
            void item.y;
            void item.width;
            const p = item.mapToItem(root, 0, 0);
            return Qt.point(p.x + item.width / 2 - width / 2, p.y + item.height + 15);
        }
        x: Math.max(8, Math.min(root.width - width - 8, anchorPos.x))
        y: anchorPos.y

        PopupShell {
            id: popupContent
            implicitWidth: promptColumn.implicitWidth + 32
            implicitHeight: promptColumn.implicitHeight + 32

            ColumnLayout {
                id: promptColumn
                anchors.centerIn: parent
                spacing: 12

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Enter password"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.pixelSize
                }

                TextField {
                    id: passwordBox
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 320
                    padding: 10
                    focus: context.promptVisible
                    enabled: !context.unlockInProgress
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData
                    color: Theme.text
                    placeholderTextColor: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.pixelSize

                    background: Rectangle {
                        color: Theme.surface0
                        radius: 6
                        border.color: passwordBox.activeFocus ? Theme.teal : Theme.surface1
                        border.width: 1
                    }

                    onTextChanged: context.currentText = text
                    onAccepted: context.tryUnlock()

                    Connections {
                        target: context
                        function onCurrentTextChanged() {
                            passwordBox.text = context.currentText;
                        }
                        function onPromptVisibleChanged() {
                            if (context.promptVisible)
                                passwordBox.forceActiveFocus();
                        }
                    }
                }

                Button {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: unlockLabel.implicitWidth + Theme.paddingH * 2
                    implicitHeight: unlockLabel.implicitHeight + Theme.paddingV * 2
                    opacity: (!context.unlockInProgress && context.currentText !== "") ? 1.0 : 0.5

                    StyledText {
                        id: unlockLabel
                        anchors.centerIn: parent
                        text: "Unlock"
                        styledBold: true
                        color: Theme.text
                    }

                    onClicked: {
                        if (!context.unlockInProgress && context.currentText !== "")
                            context.tryUnlock();
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: context.showFailure
                    text: "Incorrect password"
                    color: Theme.red
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.pixelSize
                }
            }
        }
    }

    // Catch activity anywhere else.
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.AllButtons
        hoverEnabled: false
        onPressed: root.registerActivity(true)
        onClicked: root.registerActivity(true)
        onWheel: root.registerActivity(true)
    }

    Keys.onPressed: event => {
        root.registerActivity(true);
        event.accepted = false;
    }

    focus: true
    Component.onCompleted: forceActiveFocus()
}
