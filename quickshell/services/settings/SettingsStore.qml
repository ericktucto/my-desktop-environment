pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../" as App

// Ajustes del usuario en ~/.config/stixshell/settings.json (fuera del repo, editable a mano).
// Los valores por defecto salen de Config.qml; el archivo solo recuerda lo que cambias.
// Los cambios aplican al instante, se guardan solos y las ediciones a mano se recargan.
Singleton {
    id: store

    readonly property string dir: Quickshell.env("HOME") + "/.config/stixshell"
    readonly property string filePath: dir + "/settings.json"

    // Acceso corto: SettingsStore.idle.battery.lock, SettingsStore.low.warn, SettingsStore.profiles.battery…
    readonly property var idle: data.idle
    readonly property var low: data.low
    readonly property var profiles: data.profiles
    readonly property var launcher: data.launcher
    readonly property var recorder: data.recorder
    readonly property var bluetooth: data.bluetooth

    // ── Valores del archivo (con los de Config como inicio) ──
    property JsonAdapter data: JsonAdapter {
        property JsonObject idle: JsonObject {
            property JsonObject battery: JsonObject {
                property int dim: App.Config.idle.battery.dim
                property int lock: App.Config.idle.battery.lock
                property int screenOff: App.Config.idle.battery.screenOff
                property int suspend: App.Config.idle.battery.suspend
            }
            property JsonObject ac: JsonObject {
                property int dim: App.Config.idle.ac.dim
                property int lock: App.Config.idle.ac.lock
                property int screenOff: App.Config.idle.ac.screenOff
                property int suspend: App.Config.idle.ac.suspend
            }
            property real dimLevel: App.Config.idle.dimLevel
        }
        property JsonObject low: JsonObject {
            property int warn: App.Config.idle.lowBattery.warn
            property int critical: App.Config.idle.lowBattery.critical
            property int suspend: App.Config.idle.lowBattery.suspend
        }
        property JsonObject launcher: JsonObject {
            // ids de .desktop (se reasigna el arreglo entero para que se guarde)
            property var favorites: []
        }
        property JsonObject bluetooth: JsonObject {
            property bool enabled: true     // si lo dejaste apagado, la shell lo apaga al arrancar
        }
        property JsonObject recorder: JsonObject {
            property string folder: ""      // vacío = ~/Vídeos/Grabaciones
            property string target: ""      // nombre del monitor o "region"; vacío = el primero
            property bool internal: true
            property bool mic: false
        }
        property JsonObject profiles: JsonObject {
            property string battery: App.Config.profiles.battery
            property string ac: App.Config.profiles.ac
        }
    }

    // true mientras se cambian varios valores seguidos: se guarda una sola vez al final
    property bool batching: false

    // Vuelve a los valores de Config.qml
    function reset() {
        batching = true;
        const d = App.Config.idle;
        for (const src of ["battery", "ac"])
            for (const k of ["dim", "lock", "screenOff", "suspend"])
                data.idle[src][k] = d[src][k];
        data.idle.dimLevel = d.dimLevel;
        for (const k of ["warn", "critical", "suspend"])
            data.low[k] = d.lowBattery[k];
        for (const k of ["battery", "ac"])
            data.profiles[k] = App.Config.profiles[k];
        batching = false;
        file.selfWriteRestart();
        file.writeAdapter();
    }

    // ── Pasos de tiempo (segundos; 0 = Nunca, al final de la lista) ──
    function stepUp(sec) {
        if (sec <= 0)
            return 0;
        const next = App.Config.idle.steps.find(s => s > sec);
        return next === undefined ? 0 : next;
    }

    function stepDown(sec) {
        const steps = App.Config.idle.steps;
        if (sec <= 0)
            return steps[steps.length - 1];
        const prev = steps.filter(s => s < sec);
        return prev.length > 0 ? prev[prev.length - 1] : steps[0];
    }

    function format(sec) {
        if (sec <= 0)
            return "Nunca";
        if (sec < 60)
            return sec + " s";
        if (sec < 3600) {
            const m = sec / 60;
            return (Number.isInteger(m) ? m : m.toFixed(1).replace(".", ",")) + " min";
        }
        const h = Math.floor(sec / 3600);
        const m = Math.round((sec % 3600) / 60);
        return m === 0 ? h + " h" : h + " h " + m + " min";
    }

    // ── Porcentajes de los avisos de batería (pasos de 5, 0 = apagado) ──
    function pctUp(v) {
        return Math.min(50, Math.floor(v / 5) * 5 + 5);
    }

    function pctDown(v) {
        return Math.max(0, Math.ceil(v / 5) * 5 - 5);
    }

    function pctText(v) {
        return v <= 0 ? "Apagado" : v + " %";
    }

    // La carpeta debe existir antes de leer o escribir el archivo
    Process {
        running: true
        command: ["mkdir", "-p", store.dir]
        onExited: file.path = store.filePath
    }

    // Ventana tras guardar durante la cual se ignoran los cambios del archivo
    Timer {
        id: selfWrite
        interval: 500
    }

    FileView {
        id: file
        // path se asigna cuando la carpeta ya existe
        watchChanges: true
        printErrors: false
        adapter: store.data

        function selfWriteRestart() {
            selfWrite.restart();
        }

        // Las escrituras propias también disparan fileChanged; recargarlas pisaría cambios más
        // nuevos (p. ej. al restablecer, que cambia varios valores seguidos). Se ignoran.
        onFileChanged: {
            if (!selfWrite.running)
                reload();
        }
        onAdapterUpdated: {
            if (store.batching)
                return;
            selfWrite.restart();
            writeAdapter();
        }
        onSaved: selfWrite.restart()
        // Sin archivo: se crea con los valores por defecto
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }
    }
}
