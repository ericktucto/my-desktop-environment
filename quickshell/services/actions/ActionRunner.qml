pragma Singleton
import QtQuick
import Quickshell
import "../audio/" as A
import "../brightness/" as B
import "../osd/" as O
import "../workspaces/" as W
import "../../" as App

// Acciones que se pueden asignar a un clic o a la rueda de una pill (Preferencias → Barra e isla).
// Las de los paneles llaman a los IPC de la shell (qs ipc call stixshell@…): el mismo camino que los atajos.
Singleton {
    id: runner

    // Acciones de clic: { id, label }
    readonly property var clickActions: [
        { id: "none", label: "Nada" },
        { id: "productivity", label: "Productividad (calendario)" },
        { id: "control", label: "Centro de control" },
        { id: "launcher", label: "Launcher" },
        { id: "clipboard", label: "Portapapeles" },
        { id: "workspaces", label: "Vista de workspaces" },
        { id: "windowMenu", label: "Menú de la ventana" },
        { id: "screenshot", label: "Capturar la pantalla" },
        { id: "recorder", label: "Grabar la pantalla" },
        { id: "wallpaper", label: "Selector de wallpapers" },
        { id: "session", label: "Menú de sesión" },
        { id: "nightlight", label: "Luz nocturna (alternar)" },
        { id: "playPause", label: "Reproducir o pausar" },
        { id: "mute", label: "Silenciar el audio" },
        { id: "lock", label: "Bloquear la pantalla" },
        { id: "settings", label: "Preferencias del sistema" }
    ]

    // Acciones de rueda
    readonly property var wheelActions: [
        { id: "none", label: "Nada" },
        { id: "volume", label: "Volumen" },
        { id: "brightness", label: "Brillo" },
        { id: "workspace", label: "Cambiar de workspace" }
    ]

    function label(list, id) {
        return list.find(a => a.id === id)?.label ?? id;
    }

    function ipc(target, fn, args) {
        Quickshell.execDetached(["qs", "ipc", "call", "stixshell@" + target, fn].concat(args ?? []));
    }

    // Un clic: abre un panel, lanza algo… ("none" y los desconocidos no hacen nada)
    function run(id) {
        switch (id) {
        case "productivity":
            ipc("productivity", "toggle", [""]);
            break;
        case "control":
            ipc("controlcenter", "toggle", [""]);
            break;
        case "launcher":
            ipc("launcher", "toggle", [""]);
            break;
        case "clipboard":
            ipc("clipboard", "toggle", [""]);
            break;
        case "workspaces":
            ipc("workspaces", "toggle", [""]);
            break;
        case "windowMenu":
            ipc("window", "toggle", ["window"]);
            break;
        case "screenshot":
            ipc("screenshot", "open");
            break;
        case "recorder":
            ipc("recorder", "toggle", [""]);
            break;
        case "wallpaper":
            ipc("wallpaper", "toggle", [""]);
            break;
        case "session":
            ipc("session", "toggle", [""]);
            break;
        case "nightlight":
            ipc("nightlight", "toggle");
            break;
        case "playPause":
            ipc("media", "playPause");
            break;
        case "mute":
            A.AudioStore.toggleMute(A.AudioStore.sink);
            O.OsdStore.show("volume");
            break;
        case "lock":
            ipc("lock", "lock");
            break;
        case "settings":
            ipc("settings", "toggle");
            break;
        }
    }

    // Un paso de rueda (dir = +1 arriba, -1 abajo): sube o baja el volumen o el brillo, o cambia de workspace
    function wheel(id, dir) {
        switch (id) {
        case "volume":
            A.AudioStore.step(A.AudioStore.sink, dir * A.AudioStore.keyStep);
            O.OsdStore.show("volume");
            break;
        case "brightness":
            B.BrightnessStore.step(dir * App.Config.brightness.keyStep);
            O.OsdStore.show("brightness");
            break;
        case "workspace":
            // Abajo = siguiente (como la pill de workspaces)
            W.WorkspaceStore.step(-dir);
            break;
        }
    }
}
