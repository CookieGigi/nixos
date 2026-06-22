import QtQuick
import QtQuick.Layouts
import "../components"
import "../theme"
import "../services"

PopupBase {
    id: root
    title: "Prayer Times"
    popupId: "prayer"
    popupWidth: 280

    content: ColumnLayout {
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 12

        // Hijri date header
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2

            StyledText {
                text: PrayerTimes.hijriWeekday
                styledSize: 12
                color: Theme.overlay0
                Layout.alignment: Qt.AlignHCenter
            }

            StyledText {
                text: PrayerTimes.hijriDate
                styledSize: 16
                styledBold: true
                color: Theme.accentColor
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.surface0
        }

        // Prayer list
        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true

            Repeater {
                model: PrayerTimes.prayers

                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    readonly property bool isNext: modelData.name === PrayerTimes.nextPrayerName.replace(" (tomorrow)", "")

                    StyledText {
                        text: modelData.name
                        styledBold: isNext
                        color: isNext ? Theme.accentColor : Theme.text
                        Layout.preferredWidth: 80
                    }

                    StyledText {
                        text: modelData.time
                        styledBold: isNext
                        color: isNext ? Theme.accentColor : Theme.subtext0
                        Layout.alignment: Qt.AlignRight
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
