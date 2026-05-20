import QtQuick
import QtQuick.Layouts

// A reusable clock widget. Since it starts with an uppercase letter,
// it can be referenced by name from other QML files.
Text {
    // We require the caller to pass a time string, but in this example
    // we default to the Time singleton for convenience.
    property string time: Time.time

    text: time
    color: "#ffffff"
    font {
        family: "monospace"
        pixelSize: 14
        bold: true
    }
}
