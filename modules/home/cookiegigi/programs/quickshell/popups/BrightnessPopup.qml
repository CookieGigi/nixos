import QtQuick
import QtQuick.Layouts
import "../components"
import "../services"
import "../theme"

PopupBase {
    id: root
    title: "Brightness"
    popupId: "brightness"
    popupWidth: 250

    content: ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 12

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: BrightnessStatus.ready ? BrightnessStatus.percentage + "%" : "Unavailable"
            styledBold: true
        }

        Rectangle {
            id: track
            Layout.fillWidth: true
            height: 20
            radius: 10
            color: Theme.surface0

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: parent.width * (BrightnessStatus.ready ? BrightnessStatus.percentage / 100 : 0)
                radius: 10
                color: Theme.accentColor
            }

            MouseArea {
                anchors.fill: parent
                enabled: BrightnessStatus.ready

                onClicked: mouse => BrightnessStatus.setPercentage(mouse.x / track.width * 100)
                onPositionChanged: mouse => {
                    if (pressed && mouse.x >= 0 && mouse.x <= track.width) {
                        BrightnessStatus.setPercentage(mouse.x / track.width * 100);
                    }
                }
            }
        }
    }

    onOpened: BrightnessStatus.refresh()
}
