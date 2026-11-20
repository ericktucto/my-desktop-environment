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
    readonly property var screenshot: data.screenshot
    readonly property var theme: data.theme
    readonly property var nightLight: data.nightLight
    readonly property var calendar: data.calendar
    readonly property var tasks: data.tasks
    readonly property var timer: data.timer
    readonly property var appearance: data.appearance
    readonly property var island: data.island
    readonly property var pills: data.pills
    readonly property var clock: data.clock

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
        property JsonObject screenshot: JsonObject {
            property string folder: ""      // vacío = ~/Imágenes/Capturas
            property string mode: "area"    // area | window | screen | text
            property bool editor: false
            property int delay: 0           // segundos antes de congelar la pantalla (0, 3 o 5)
            property string tool: "arrow"
            property int color: 0           // posición en Config.screenshot.colors
            property int size: 1            // posición en Config.screenshot.strokes
            property bool fill: false       // rectángulos y elipses rellenos
            property bool textBackground: false
            property bool blur: false       // false = pixelar, true = difuminar
        }
        property JsonObject theme: JsonObject {
            property string mode: ""                        // scheme (colores del wallpaper) | accent (acento del wallpaper) | custom (acento propio); vacío = se deduce de dynamic y tint
            property string color: "#2979ff"                // el acento propio
            property bool dynamic: true                     // solo para la migración (antes: colores según el wallpaper)
            property string scheme: "scheme-tonal-spot"
            property string tint: "tinted"                  // intensidad del modo «colores del wallpaper»: tinted | vivid (neutral se lee como tinted)
            property var sources: ({})                      // ruta del wallpaper → color fuente elegido (0 a 3)
        }
        property JsonObject nightLight: JsonObject {
            property bool enabled: false
            property string mode: "sun"                     // sun (atardecer a amanecer) | custom (horas fijas) | always
            property int temperature: App.Config.nightLight.temperature
            property string start: App.Config.nightLight.start
            property string end: App.Config.nightLight.end
            property string latitude: ""                    // vacío = de la zona horaria
            property string longitude: ""
            property real pausedUntil: 0                    // ms desde 1970; la pausa vuelve sola
        }
        property JsonObject calendar: JsonObject {
            property string view: "month"                   // month | week | days3 | day
            property int refresh: 0                         // minutos entre actualizaciones; 0 = al abrir, al iniciar y al despertar
        }
        property JsonObject tasks: JsonObject {
            property string view: "today"                   // today | upcoming | inbox | board | done | project:<id> | tag:<nombre>
            property string sort: "manual"                  // manual | due | priority
            property string lastTab: "calendar"             // calendar | tasks | timer | stopwatch
            property string lastSummary: ""                 // AAAA-MM-DD del último resumen de la mañana
        }
        property JsonObject timer: JsonObject {
            property string sound: "system"                 // system (alarm-clock-elapsed) o la ruta de un archivo de audio
        }
        property JsonObject profiles: JsonObject {
            property string battery: App.Config.profiles.battery
            property string ac: App.Config.profiles.ac
        }
        // Qué hace cada clic y la rueda sobre la isla central (ids de services/actions/ActionRunner.qml)
        property JsonObject island: JsonObject {
            property string left: "productivity"
            property string right: "control"
            property string middle: "none"
            property string wheel: "volume"
            property string shiftWheel: "brightness"
        }
        // Qué pills se ven en la barra (las que dependen de algo, como la red o Bluetooth, además lo necesitan)
        property JsonObject pills: JsonObject {
            property bool activeWindow: true
            property bool zoom: true
            property bool tray: true
            property bool network: true
            property bool bluetooth: true
            property bool battery: true
            property bool notifications: true
        }
        property JsonObject clock: JsonObject {
            property bool hour12: true      // 12 h con AM/PM; apagado = 24 h
            property bool seconds: false
        }
        property JsonObject appearance: JsonObject {
            property bool animations: true                  // false = sin animaciones (todas las duraciones en 0)
            property string wallpaperDir: ""                // vacío = Config.wallpaperPicker.dir
        }
    }

    // Preferencias → Apariencia → Animaciones
    Binding {
        target: App.Config
        property: "animScale"
        value: store.data.appearance.animations ? 1 : 0
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

    // Restablece una sección a los valores de fábrica (los de Config.qml o los iniciales de arriba).
    // `energy` = inactividad, avisos de batería y perfiles (lo mismo que reset()).
    function resetSection(name) {
        if (name === "energy") {
            reset();
            return;
        }
        batching = true;
        if (name === "theme") {
            data.theme.mode = "";
            data.theme.color = "#2979ff";
            data.theme.scheme = "scheme-tonal-spot";
            data.theme.tint = "tinted";
        } else if (name === "nightLight") {
            data.nightLight.mode = "sun";
            data.nightLight.temperature = App.Config.nightLight.temperature;
            data.nightLight.start = App.Config.nightLight.start;
            data.nightLight.end = App.Config.nightLight.end;
            data.nightLight.latitude = "";
            data.nightLight.longitude = "";
        } else if (name === "island") {
            data.island.left = "productivity";
            data.island.right = "control";
            data.island.middle = "none";
            data.island.wheel = "volume";
            data.island.shiftWheel = "brightness";
        } else if (name === "pills") {
            for (const k of ["activeWindow", "zoom", "tray", "network", "bluetooth", "battery", "notifications"])
                data.pills[k] = true;
        } else if (name === "clock") {
            data.clock.hour12 = true;
            data.clock.seconds = false;
        } else if (name === "appearance") {
            data.appearance.animations = true;
            data.appearance.wallpaperDir = "";
        }
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
