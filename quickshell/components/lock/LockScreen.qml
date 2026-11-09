import QtQuick
import Quickshell.Wayland
import "../../services/lock/" as L

// Pantalla de bloqueo (ext-session-lock): una superficie por monitor.
WlSessionLock {
    locked: L.LockStore.locked

    WlSessionLockSurface {
        color: "black"

        LockSurface {}
    }
}
