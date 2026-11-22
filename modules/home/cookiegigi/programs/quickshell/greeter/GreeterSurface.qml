import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "components"
import "theme"

// Fullscreen greeter surface: wallpaper + dim overlay (mirroring the
// lockscreen), a clock column, and a centered login card using the same
// popup/TextField styling as the lockscreen prompt.
Rectangle {
    id: root

    required property var context
    required property var screen

    color: Theme.base

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Image {
        anchors.fill: parent
        // Bundled into the greeter config by the build in quickshell/default.nix,
        // so the greeter user does not need access to ~/.config or ~/nixos.
        source: "wallpaper.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#40000000"
    }

    // Clock + date, like a lock screen.
    ColumnLayout {
        anchors {
            top: parent.top
            topMargin: 64
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 8

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "hh:mm")
            styledSize: 72
            styledBold: true
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "dddd d MMMM")
            styledSize: 20
            styledColor: Theme.subtext1
        }
    }

    // Login card, styled like the lockscreen password popup.
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: cardColumn.implicitWidth + 48
        height: cardColumn.implicitHeight + 48
        radius: 12
        color: Theme.containerAlpha
        border.width: 1
        border.color: root.context.showFailure ? Theme.red : Theme.popupBorder

        ColumnLayout {
            id: cardColumn
            anchors.centerIn: parent
            spacing: 12

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Welcome back"
                styledSize: 18
                styledBold: true
            }

            // Username
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "User"
                    styledSize: 12
                    styledColor: Theme.subtext0
                }

                TextField {
                    id: userBox
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 320
                    padding: 10
                    enabled: !root.context.authInProgress
                    color: Theme.text
                    placeholderTextColor: Theme.subtext0
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.pixelSize
                    }
                    text: root.context.userText
                    background: Rectangle {
                        color: Theme.surface0
                        radius: 6
                        border.color: userBox.activeFocus ? Theme.teal : Theme.surface1
                        border.width: 1
                    }
                    onTextEdited: root.context.userText = text
                    onAccepted: passwordBox.forceActiveFocus()
                }
            }

            // Password
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Password"
                    styledSize: 12
                    styledColor: Theme.subtext0
                }

                TextField {
                    id: passwordBox
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 320
                    padding: 10
                    enabled: !root.context.authInProgress
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData
                    color: Theme.text
                    placeholderTextColor: Theme.subtext0
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.pixelSize
                    }
                    background: Rectangle {
                        color: Theme.surface0
                        radius: 6
                        border.color: root.context.showFailure ? Theme.red : (passwordBox.activeFocus ? Theme.teal : Theme.surface1)
                        border.width: 1
                    }
                    onTextEdited: root.context.passwordText = text
                    onAccepted: root.context.tryLogin()

                    // Auth failure clears the context; write it back here
                    // (same pattern as the lockscreen prompt).
                    Connections {
                        target: root.context
                        function onPasswordTextChanged() {
                            passwordBox.text = root.context.passwordText;
                        }
                    }
                }
            }

            // Failure message.
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: root.context.showFailure
                text: root.context.failureMessage
                styledColor: Theme.red
            }
        }
    }

    // Dry-run notice when the config is launched outside greetd
    // (e.g. `qs -p .../quickshell/greeter` inside the user session).
    StyledText {
        anchors {
            bottom: parent.bottom
            bottomMargin: 24
            horizontalCenter: parent.horizontalCenter
        }
        visible: !root.context.available
        text: "greetd socket unavailable — dry-run mode · Esc to exit"
        styledColor: Theme.subtext0
    }

    // A dry run covers the whole session with exclusive keyboard focus and
    // has no way out otherwise. Never escape a real greeter (the login screen
    // is the point), hence the available check.
    Keys.onEscapePressed: event => {
        if (!root.context.available)
            Qt.quit();
    }

    // Reclaim keyboard focus wherever the user interacts.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: passwordBox.forceActiveFocus()
        onWheel: passwordBox.forceActiveFocus()
        z: -1
    }

    // Only the primary surface grabs keyboard focus at startup;
    // other screens acquire it on interaction.
    Component.onCompleted: {
        if (root.screen && root.screen.primary)
            passwordBox.forceActiveFocus();
    }
}
