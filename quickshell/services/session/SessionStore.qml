pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../lock/" as L
import "../../" as App

// Acciones de sesión (bloquear, suspender, cerrar sesión, reiniciar, apagar)
// y el inhibidor que reserva el botón físico de encendido para la shell.
Singleton {
    id: store

    readonly property var actions: [
        {
            id: "lock",
            text: "Bloquear",
            confirmText: "",
            icon: "lock",
            confirm: false
        },
        {
            id: "suspend",
            text: "Suspender",
            confirmText: "",
            icon: "suspend",
            confirm: false
        },
        {
            id: "logout",
            text: "Cerrar sesión",
            confirmText: "¿Cerrar sesión?",
            icon: "logout",
            confirm: true
        },
        {
            id: "reboot",
            text: "Reiniciar",
            confirmText: "¿Reiniciar?",
            icon: "restart",
            confirm: true
        },
        {
            id: "poweroff",
            text: "Apagar",
            confirmText: "¿Apagar?",
            icon: "shutdown",
            confirm: true
        }
    ]

    function exec(cmd) {
        if (App.Config.session.dryRun)
            console.log("[session dryRun]", cmd.join(" "));
        else
            Quickshell.execDetached(cmd);
    }

    // Pantalla de bloqueo propia (services/lock); si la shell no corre, hypridle usa hyprlock
    function lock() {
        L.LockStore.lock();
    }

    function run(id) {
        switch (id) {
        case "lock":
            lock();
            break;
        case "suspend":
            lock();
            suspendTimer.restart();
            break;
        case "logout":
            exec(["hyprctl", "dispatch", "hl.dsp.exit()"]);
            break;
        case "reboot":
            exec(["loginctl", "reboot"]);
            break;
        case "poweroff":
            exec(["loginctl", "poweroff"]);
            break;
        }
    }

    Timer {
        id: suspendTimer
        interval: App.Config.session.suspendDelay
        onTriggered: store.exec(["loginctl", "suspend"])
    }

    // Mientras la shell corre, elogind ignora el botón de encendido y lo usa Hyprland.
    // Si qs muere, el proceso muere y el botón vuelve a apagar.
    Process {
        running: true
        command: ["elogind-inhibit", "--what=handle-power-key", "--mode=block", "--who=stixshell", "--why=Menú de sesión", "sleep", "infinity"]
    }
}
