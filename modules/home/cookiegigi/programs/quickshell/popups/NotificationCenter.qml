import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import "../components"
import "../services"
import "../theme"

PopupBase {
    id: root
    title: "Notifications"
    popupId: "notifications"
    popupWidth: 420
    implicitHeight: Math.max(1, Math.min(600, (screen?.height ?? 720) - marginTop - 24))
    property bool showHistory: false
    property bool countedOpen: false
    readonly property var entries: showHistory ? Notifications.history : Notifications.active

    onOpened: {
        if (countedOpen)
            return;
        countedOpen = true;
        Notifications.openCenters++;
        Notifications.refresh();
    }
    onClosing: {
        if (countedOpen)
            Notifications.openCenters--;
        countedOpen = false;
    }
    Component.onDestruction: {
        if (countedOpen)
            Notifications.openCenters--;
    }
    controller.handleLeftRight: true
    controller.onNavigateLeft: showHistory = false
    controller.onNavigateRight: showHistory = true
    controller.onNavigateDown: list.contentY = Math.min(Math.max(0, list.contentHeight - list.height), list.contentY + 80)
    controller.onNavigateUp: list.contentY = Math.max(0, list.contentY - 80)
    onShowHistoryChanged: list.positionViewAtBeginning()

    component Chip: Controls.Button {
        id: chip
        property bool selected: false
        hoverEnabled: true
        padding: 8
        verticalPadding: 5
        contentItem: StyledText {
            text: chip.text
            textFormat: Text.PlainText
            styledSize: 11
            styledBold: chip.selected
            color: !chip.enabled ? Theme.overlay0 : chip.selected ? Theme.crust : Theme.text
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 7
            color: chip.selected ? Theme.teal : chip.hovered ? Theme.surface1 : Theme.surface0
            border.width: chip.visualFocus ? 1 : 0
            border.color: Theme.teal
        }
    }

    content: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                Layout.fillWidth: true
                text: "Notifications"
                styledSize: 12
                styledBold: true
            }
            Chip {
                text: Notifications.quiet ? "\uf1f6" : "\uf0f3"
                selected: Notifications.quiet
                enabled: Notifications.available && !Notifications.busy
                onClicked: Notifications.run(["mode", "-t", "do-not-disturb"])
                Accessible.name: Notifications.quiet ? "Unmute notifications" : "Mute notifications"
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: Accessible.name
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Chip {
                text: "Active  " + Notifications.active.length
                selected: !root.showHistory
                onClicked: root.showHistory = false
            }
            Chip {
                text: "History  " + Notifications.history.length
                selected: root.showHistory
                onClicked: root.showHistory = true
            }
            Item {
                Layout.fillWidth: true
            }
            Chip {
                text: root.showHistory ? "Restore" : "Dismiss all"
                enabled: Notifications.available && !Notifications.busy && root.entries.length > 0
                onClicked: Notifications.run(root.showHistory ? ["restore"] : ["dismiss", "--all"])
                Accessible.name: root.showHistory ? "Restore latest notification" : "Dismiss all active notifications"
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: !Notifications.available || Notifications.error !== ""
            text: !Notifications.available ? "Cannot reach Mako. Retrying automatically..." : Notifications.error
            color: Theme.peach
            styledSize: 11
            wrapMode: Text.Wrap
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                visible: root.entries.length === 0 && Notifications.available
                spacing: 8
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "\uf0f3"
                    styledSize: 20
                    color: Theme.teal
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.showHistory ? "A fresh start" : "All caught up"
                    styledSize: 12
                    styledBold: true
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.showHistory ? "Dismissed updates will appear here." : "Nothing needs your attention right now."
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    styledSize: 11
                    color: Theme.subtext0
                }
            }

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                spacing: 10
                model: root.entries
                boundsBehavior: Flickable.StopAtBounds
                Controls.ScrollBar.vertical: Controls.ScrollBar {}
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    width: list.width - 10
                    implicitHeight: cardContent.implicitHeight + 20
                    radius: 10
                    color: Theme.mantle
                    border.color: modelData.urgency === "critical" ? Theme.peach : Theme.surface0

                    ColumnLayout {
                        id: cardContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 6
                        RowLayout {
                            Layout.fillWidth: true
                            StyledText {
                                Layout.fillWidth: true
                                text: (card.modelData.app_name || "System").toUpperCase()
                                textFormat: Text.PlainText
                                styledSize: 10
                                font.letterSpacing: 1
                                color: card.modelData.urgency === "critical" ? Theme.peach : Theme.teal
                                elide: Text.ElideRight
                            }
                            Chip {
                                visible: !root.showHistory
                                text: "Dismiss"
                                enabled: Notifications.available && !Notifications.busy
                                onClicked: Notifications.run(["dismiss", "-n", String(card.modelData.id)])
                            }
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: card.modelData.summary || "Notification"
                            textFormat: Text.PlainText
                            styledSize: 12
                            styledBold: true
                            wrapMode: Text.Wrap
                        }
                        StyledText {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: card.modelData.body || ""
                            // Never interpret notification-supplied HTML or load remote images.
                            textFormat: Text.PlainText
                            styledSize: 10
                            color: Theme.subtext0
                            wrapMode: Text.Wrap
                        }
                        Flow {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: !root.showHistory
                            Repeater {
                                model: root.showHistory ? [] : Object.keys(card.modelData.actions || {})
                                Chip {
                                    required property string modelData
                                    width: Math.min(implicitWidth, parent.width)
                                    text: card.modelData.actions[modelData] || "Open"
                                    enabled: Notifications.available && !Notifications.busy
                                    onClicked: Notifications.run(["invoke", "-n", String(card.modelData.id), modelData])
                                }
                            }
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.showHistory ? "Recent history from Mako / restore brings back latest" : "ESC close / LEFT-RIGHT tabs / UP-DOWN scroll"
            styledSize: 9
            color: Theme.overlay1
            wrapMode: Text.Wrap
        }
    }
}
