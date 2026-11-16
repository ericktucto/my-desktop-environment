import QtQuick
import Quickshell.Wayland
import "../../services/lock/" as L

// Pantalla de bloqueo (ext-session-lock): una superficie por monitor.
WlSessionLock {
    locked: L.LockStore.locked

    WlSessionLockSurface {
        id: surface
        color: "black"

        LockSurface {
            screenName: surface.screen ? surface.screen.name : ""
        }
    }
}
