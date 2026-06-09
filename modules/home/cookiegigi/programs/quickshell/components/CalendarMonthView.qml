import QtQuick
import QtQuick.Layouts
import "../theme"

// Reusable month calendar widget.
// Displays a month grid with navigation arrows, day-of-week headers,
// and day cells. Signals selectedDateChanged and displayDateChanged on change.
ColumnLayout {
    id: root

    property var today: new Date()
    property var selectedDate: new Date(today)
    property var displayDate: new Date(today.getFullYear(), today.getMonth(), 1)

    spacing: 12

    // Month navigation
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: prevMonthArea.containsMouse ? Theme.surface1 : "transparent"

            StyledText {
                anchors.centerIn: parent
                text: "<"
                styledBold: true
                styledSize: 14
                color: prevMonthArea.containsMouse ? Theme.text : Theme.overlay1
            }

            MouseArea {
                id: prevMonthArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.previousMonth()
            }
        }

        StyledText {
            text: Qt.formatDateTime(root.displayDate, "MMMM yyyy")
            styledBold: true
            styledSize: 14
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: nextMonthArea.containsMouse ? Theme.surface1 : "transparent"

            StyledText {
                anchors.centerIn: parent
                text: ">"
                styledBold: true
                styledSize: 14
                color: nextMonthArea.containsMouse ? Theme.text : Theme.overlay1
            }

            MouseArea {
                id: nextMonthArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.nextMonth()
            }
        }
    }

    // Day of week headers
    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            delegate: StyledText {
                required property var modelData
                text: modelData
                styledBold: true
                styledSize: 12
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: Theme.overlay1
            }
        }
    }

    // Calendar grid
    GridLayout {
        id: dayGrid
        Layout.fillWidth: true
        Layout.preferredHeight: 6 * 32 + 5 * 4
        columns: 7
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: root.generateDays(root.displayDate)
            delegate: CalendarDayCell {
                required property var modelData
                Layout.fillWidth: true
                day: modelData.day
                isToday: modelData.isToday
                isSelected: modelData.isSelected
                isOtherMonth: modelData.isOtherMonth
                onClicked: {
                    if (!modelData.isOtherMonth) {
                        root.selectedDate = new Date(modelData.year, modelData.month, modelData.day);
                    } else {
                        root.displayDate = new Date(modelData.year, modelData.month, 1);
                        root.selectedDate = new Date(modelData.year, modelData.month, modelData.day);
                    }
                }
            }
        }
    }

    function previousMonth() {
        const year = root.displayDate.getFullYear();
        const month = root.displayDate.getMonth();
        root.displayDate = new Date(year, month - 1, 1);
    }

    function nextMonth() {
        const year = root.displayDate.getFullYear();
        const month = root.displayDate.getMonth();
        root.displayDate = new Date(year, month + 1, 1);
    }

    function generateDays(date) {
        if (!date || !(date instanceof Date)) {
            return [];
        }
        const year = date.getFullYear();
        const month = date.getMonth();
        const firstDay = new Date(year, month, 1);
        const lastDay = new Date(year, month + 1, 0);
        const daysInMonth = lastDay.getDate();

        // Monday = 0, Sunday = 6
        const startOffset = (firstDay.getDay() + 6) % 7;

        const days = [];
        const sel = root.selectedDate;
        const t = root.today;

        // Previous month trailing days
        const prevMonthLastDay = new Date(year, month, 0).getDate();
        for (let i = startOffset - 1; i >= 0; i--) {
            const d = prevMonthLastDay - i;
            const prevMonth = month === 0 ? 11 : month - 1;
            const prevYear = month === 0 ? year - 1 : year;
            days.push({
                day: d,
                month: prevMonth,
                year: prevYear,
                isToday: false,
                isSelected: false,
                isOtherMonth: true
            });
        }

        // Current month days
        for (let d = 1; d <= daysInMonth; d++) {
            const isToday = d === t.getDate() && month === t.getMonth() && year === t.getFullYear();
            const isSelected = d === sel.getDate() && month === sel.getMonth() && year === sel.getFullYear();
            days.push({
                day: d,
                month: month,
                year: year,
                isToday: isToday,
                isSelected: isSelected,
                isOtherMonth: false
            });
        }

        // Next month leading days to fill the grid (6 rows = 42 cells)
        const remaining = 42 - days.length;
        for (let d = 1; d <= remaining; d++) {
            const nextMonth = month === 11 ? 0 : month + 1;
            const nextYear = month === 11 ? year + 1 : year;
            days.push({
                day: d,
                month: nextMonth,
                year: nextYear,
                isToday: false,
                isSelected: false,
                isOtherMonth: true
            });
        }

        return days;
    }
}
