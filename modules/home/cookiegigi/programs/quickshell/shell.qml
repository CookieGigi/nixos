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

    IpcHandler {
        target: "calendar"
        function toggle(): void {
            const screen = Quickshell.screens.find(s => s.primary) ?? Quickshell.screens[0];
            PopupRegistry.toggleCalendar(screen);
        }
    }

    IpcHandler {
        target: "media"
        function toggle(): void {
            const screen = Quickshell.screens.find(s => s.primary) ?? Quickshell.screens[0];
            PopupRegistry.toggleMedia(screen);
        }
    }

    IpcHandler {
        target: "volume"
        function toggle(): void {
            const screen = Quickshell.screens.find(s => s.primary) ?? Quickshell.screens[0];
            PopupRegistry.toggleVolume(screen);
        }
    }

    IpcHandler {
        target: "brightness"
        function toggle(): void {
            const screen = Quickshell.screens.find(s => s.primary) ?? Quickshell.screens[0];
            PopupRegistry.toggleBrightness(screen);
        }
    }

    IpcHandler {
        target: "battery"
        function toggle(): void {
            const screen = Quickshell.screens.find(s => s.primary) ?? Quickshell.screens[0];
            PopupRegistry.toggleBattery(screen);
        }
    }

    IpcHandler {
        target: "bluetooth"
        function toggle(): void {
            const screen = Quickshell.screens.find(s => s.primary) ?? Quickshell.screens[0];
            PopupRegistry.toggleBluetooth(screen);
        }
    }

    IpcHandler {
        target: "prayer"
        function toggle(): void {
            const screen = Quickshell.screens.find(s => s.primary) ?? Quickshell.screens[0];
            PopupRegistry.togglePrayer(screen);
        }
    }

    Variants {
        model: Quickshell.screens
        Bar {
            modelData: modelData
        }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void {
            const screen = Quickshell.screens.find(s => s.primary) ?? Quickshell.screens[0];
            PopupRegistry.toggle(screen, "notifications");
        }
    }

    // Tell the session-opening splash (spawned by niri at session start)
    // that the shell is up so it fades out. Fire-and-forget: the call
    // fails silently when no splash instance is running (e.g. reloads).
    // NOTE: ShellRoot does not support attached properties like
    // Component.onCompleted ("Non-existent attached object", fatal), so
    // run the call straight from the declarative running binding.
    Process {
        command: ["qs", "-c", "splash", "ipc", "call", "splash", "dismiss"]
        running: true
    }
}
