import QtQuick
import QtQuick.Layouts
import "../components"
import "../theme"

PopupBase {
    id: root
    title: "Calendar"
    popupId: "calendar"
    popupWidth: 320
    implicitHeight: monthView.implicitHeight + 32

    property var today: new Date()
    property var selectedDate: new Date(today)

    onOpened: {
        controller.handleLeftRight = true;
        controller.navigateLeft.connect(monthView.previousMonth);
        controller.navigateRight.connect(monthView.nextMonth);
    }

    onClosing: {
        controller.navigateLeft.disconnect(monthView.previousMonth);
        controller.navigateRight.disconnect(monthView.nextMonth);
        controller.handleLeftRight = false;
    }

    content: ColumnLayout {
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 12

        // Reusable month calendar widget
        CalendarMonthView {
            id: monthView
            Layout.fillWidth: true
            today: root.today
            Component.onCompleted: selectedDate = root.selectedDate
            onSelectedDateChanged: root.selectedDate = monthView.selectedDate
        }
    }
}
