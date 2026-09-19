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
    implicitHeight: prayerContent.implicitHeight + 32
    onOpened: {
        PrayerTimes._updateNextPrayer();
        if (!PrayerTimes.ready)
            PrayerTimes.refresh();
    }

    content: ColumnLayout {
        id: prayerContent
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 12

        StyledText {
            visible: !PrayerTimes.ready
            text: PrayerTimes.loading ? "Loading prayer times..." : "Prayer times unavailable"
            color: Theme.subtext0
            Layout.alignment: Qt.AlignHCenter
        }

        // Hijri date header
        ColumnLayout {
            visible: PrayerTimes.ready
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
            visible: PrayerTimes.ready
            Layout.fillWidth: true
            height: 1
            color: Theme.surface0
        }

        // Prayer list
        ColumnLayout {
            visible: PrayerTimes.ready
            spacing: 6
            Layout.fillWidth: true

            Repeater {
                model: !PrayerTimes.ready ? [] : PrayerTimes.nextPrayerName === "Fajr (tomorrow)" ? PrayerTimes.prayers.concat([
                    {
                        name: PrayerTimes.nextPrayerName,
                        time: PrayerTimes.nextPrayerTime
                    }
                ]) : PrayerTimes.prayers

                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    readonly property bool isNext: modelData.name === PrayerTimes.nextPrayerName

                    StyledText {
                        text: modelData.name
                        styledBold: isNext
                        color: isNext ? Theme.accentColor : Theme.text
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
