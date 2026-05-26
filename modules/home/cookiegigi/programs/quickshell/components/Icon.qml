import QtQuick
import "../theme"

// Consistent emoji / icon text.
// Set text to the desired emoji or symbol.
Text {
    property int iconSize: 14

    font {
        family: Theme.fontFamily
        pixelSize: iconSize
    }
    color: Theme.text
}
