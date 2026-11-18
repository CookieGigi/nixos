import QtQuick
import "../components"
import "../services"

Percentage {
    id: root

    property var screen: null

    icon: BrightnessStatus.percentage < 20 ? "󰃞" : "󰃠"
    value: BrightnessStatus.ready ? BrightnessStatus.percentage + "%" : "?%"

    onClicked: {
        if (screen) {
            PopupRegistry.toggleBrightness(screen);
        }
    }
}
