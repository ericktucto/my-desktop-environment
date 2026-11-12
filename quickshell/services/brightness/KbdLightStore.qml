pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Luz del teclado (platform::kbd_backlight en la IdeaPad) con brightnessctl. No necesita sudo: el usuario
// está en el grupo `input`. sysfs no avisa los cambios, así que se vuelve a leer al abrir el centro de control.
Singleton {
    id: store

    property string device: ""
    property int level: 0
    property int max: 0
    readonly property bool available: device !== "" && max > 0
    readonly property bool on: level > 0

    readonly property string label: {
        if (!available)
            return "No disponible";
        if (max <= 1)
            return on ? "Encendida" : "Apagada";
        return on ? "Nivel " + level + " de " + max : "Apagada";
    }

    function refresh() {
        if (device === "")
            findProc.running = true;
        else
            infoProc.running = true;
    }

    // Pasa al siguiente nivel; tras el último, apaga
    function toggle() {
        if (!available)
            return;
        level = level >= max ? 0 : level + 1;
        Quickshell.execDetached(["brightnessctl", "-d", device, "-q", "set", String(level)]);
    }

    // brightnessctl -m: nombre,clase,actual,porcentaje,máximo
    function parse(line) {
        const f = line.trim().split(",");
        if (f.length < 5)
            return;
        store.device = f[0];
        store.level = parseInt(f[2]);
        store.max = parseInt(f[4]);
    }

    Process {
        id: findProc
        command: ["brightnessctl", "-m", "-c", "leds", "-l"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.split("\n").find(l => l.split(",")[0].indexOf("kbd_backlight") >= 0);
                if (line)
                    store.parse(line);
            }
        }
    }

    Process {
        id: infoProc
        command: ["brightnessctl", "-d", store.device, "-m", "info"]
        stdout: StdioCollector {
            onStreamFinished: store.parse(text)
        }
    }

    Component.onCompleted: refresh()
}
