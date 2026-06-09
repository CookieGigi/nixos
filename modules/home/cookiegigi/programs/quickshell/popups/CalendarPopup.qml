import QtQuick
import QtQuick.Layouts
import "../components"
import "../theme"

PopupBase {
    id: root
    title: "Calendar"
    popupId: "calendar"
    popupWidth: 280

    property var currentDate: new Date()

    content: ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 8

        StyledText {
            text: Qt.formatDateTime(root.currentDate, "dddd d MMMM yyyy")
            styledBold: true
            styledSize: 16
            Layout.alignment: Qt.AlignHCenter
        }

        StyledText {
            text: Qt.formatDateTime(root.currentDate, "hh:mm")
            styledSize: 14
            color: Theme.accentColor
            Layout.alignment: Qt.AlignHCenter
        }

        // Month header
        StyledText {
            text: Qt.formatDateTime(root.currentDate, "MMMM yyyy")
            styledBold: true
            styledSize: 14
            Layout.alignment: Qt.AlignHCenter
        }

        // Day headers
        RowLayout {
            Layout.fillWidth: true
            spacing: 2
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                delegate: StyledText {
                    text: modelData
                    styledBold: true
                    styledSize: 12
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.overlay1
                }
            }
        }

        GridLayout {
            id: dayGrid
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 2
            columnSpacing: 2

            Repeater {
                model: generateDays(root.currentDate)
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: 4
                    color: modelData.isToday ? Theme.accentColor : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: modelData.day || ""
                        color: modelData.isToday ? Theme.base : Theme.text
                        styledSize: 12
                    }
                }
            }
        }
    }

    function generateDays(date) {
        const year = date.getFullYear();
        const month = date.getMonth();
        const firstDay = new Date(year, month, 1);
        const lastDay = new Date(year, month + 1, 0);
        const startOffset = (firstDay.getDay() + 6) % 7; // Monday = 0

        const days = [];
        // Empty slots for offset
        for (let i = 0; i < startOffset; i++) {
            days.push({
                day: "",
                isToday: false
            });
        }
        const today = new Date();
        for (let d = 1; d <= lastDay.getDate(); d++) {
            const isToday = d === today.getDate() && month === today.getMonth() && year === today.getFullYear();
            days.push({
                day: d,
                isToday: isToday
            });
        }
        return days;
    }
}
