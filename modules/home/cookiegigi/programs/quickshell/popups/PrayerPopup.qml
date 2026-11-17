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

    content: Item {
        id: prayerContent
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 16
        }
        implicitHeight: contentColumn.implicitHeight

        Column {
            id: contentColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            spacing: 12

            StyledText {
                visible: !PrayerTimes.ready
                width: parent.width
                text: PrayerTimes.loading ? "Loading prayer times..." : "Prayer times unavailable"
                color: Theme.subtext0
                horizontalAlignment: Text.AlignHCenter
            }

            // Hijri date header
            Column {
                visible: PrayerTimes.ready
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2

                StyledText {
                    text: PrayerTimes.hijriWeekday
                    styledSize: 12
                    color: Theme.overlay0
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    text: PrayerTimes.hijriDate
                    styledSize: 16
                    styledBold: true
                    color: Theme.accentColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // Separator
            Rectangle {
                visible: PrayerTimes.ready
                width: parent.width
                height: 1
                color: Theme.surface0
            }

            // Prayer list
            Column {
                visible: PrayerTimes.ready
                width: parent.width
                spacing: 6

                Repeater {
                    model: !PrayerTimes.ready ? [] : PrayerTimes.nextPrayerName === "Fajr (tomorrow)" ? PrayerTimes.prayers.concat([
                        {
                            name: PrayerTimes.nextPrayerName,
                            time: PrayerTimes.nextPrayerTime
                        }
                    ]) : PrayerTimes.prayers

                    Row {
                        id: prayerRow
                        width: parent.width
                        spacing: 12

                        readonly property bool isNext: modelData.name === PrayerTimes.nextPrayerName

                        StyledText {
                            id: prayerNameText
                            width: Math.max(0, prayerRow.width - prayerTimeText.implicitWidth - prayerRow.spacing)
                            text: modelData.name
                            styledBold: prayerRow.isNext
                            color: prayerRow.isNext ? Theme.accentColor : Theme.text
                            elide: Text.ElideRight
                        }

                        StyledText {
                            id: prayerTimeText
                            width: implicitWidth
                            text: modelData.time
                            styledBold: prayerRow.isNext
                            color: prayerRow.isNext ? Theme.accentColor : Theme.subtext0
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
    }
}
