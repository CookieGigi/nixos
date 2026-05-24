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
            const v = Visibilities.getForActive();
            if (v) v.launcher = !v.launcher;
        }
    }

    IpcHandler {
        target: "power"
        function toggle(): void {
            const v = Visibilities.getForActive();
            if (v) v.power = !v.power;
        }
    }

    Variants {
        model: Quickshell.screens
        Bar {
            modelData: modelData
        }
    }
}
