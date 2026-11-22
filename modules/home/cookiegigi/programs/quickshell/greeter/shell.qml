import Quickshell
import Quickshell.Wayland

// Greeter entry point for greetd.
//
// Unlike the lockscreen (WlSessionLock, runs inside the user session),
// the greeter renders one overlay layer surface per output and talks to
// greetd through Quickshell.Services.Greetd.
//
// Failed auth stays here; a successful login calls Greetd.launch() with
// the niri session command substituted into GreeterContext.qml at build time.
ShellRoot {
    GreeterContext {
        id: greeterContext
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            required property var modelData
            screen: window.modelData

            // Layer-shell specifics are attached properties:
            // exclusive keyboard focus + overlay layer like the lockscreen.
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            surfaceFormat.opaque: false

            GreeterSurface {
                anchors.fill: parent
                context: greeterContext
                screen: window.modelData
            }
        }
    }
}
