import QtQuick
import Quickshell

// This is the entry point of the quickshell configuration.
// Quickshell looks for a file named `shell.qml` as the root.
//
// You can run this example with:
//   qs -p shell.qml
//
// Or, if you copy this folder to ~/.config/quickshell/my-widget/,
// you can run it with:
//   qs -c my-widget

Scope {
    // Load the top bar (creates one per monitor).
    Bar {}
}
