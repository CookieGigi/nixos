import QtQuick
import "../theme"

// Text with Catppuccin theme defaults.
// Override styledSize, styledColor, or styledBold as needed.
Text {
    property int styledSize: Theme.pixelSize
    property color styledColor: Theme.text
    property bool styledBold: false

    font {
        family: Theme.fontFamily
        pixelSize: styledSize
        bold: styledBold
    }
    color: styledColor
}
