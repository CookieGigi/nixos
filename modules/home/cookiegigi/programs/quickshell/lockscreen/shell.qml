import Quickshell
import Quickshell.Wayland

ShellRoot {
    LockContext {
        id: lockContext

        onUnlocked: {
            lock.locked = false;
            Qt.quit();
        }
    }

    WlSessionLock {
        id: lock
        locked: true

        WlSessionLockSurface {
            id: lockSurface
            LockSurface {
                anchors.fill: parent
                context: lockContext
                screen: lockSurface.screen
            }
        }
    }
}
