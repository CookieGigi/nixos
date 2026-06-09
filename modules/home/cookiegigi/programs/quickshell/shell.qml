//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
import Quickshell
import Quickshell.Io
import "modules"
import "services"

// Shell entry point.
// Exposes IPC targets so niri keybinds can control popups.
ShellRoot {
    settings.watchFiles: true

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            const screen = Quickshell.screens.find(s => s.primary) ?? Quickshell.screens[0];
            PopupRegistry.toggleLauncher(screen);
        }
    }

    IpcHandler {
        target: "power"
        function toggle(): void {
            const screen = Quickshell.screens.find(s => s.primary) ?? Quickshell.screens[0];
            PopupRegistry.togglePower(screen);
        }
    }

    IpcHandler {
        target: "network"
        function toggle(): void {
            const screen = Quickshell.screens.find(s => s.primary) ?? Quickshell.screens[0];
            PopupRegistry.toggleNetwork(screen);
        }
    }

    Variants {
        model: Quickshell.screens
        Bar {
            modelData: modelData
        }
    }
}
