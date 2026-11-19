pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../settings/" as ST
import "../../" as App

// Colores dinámicos según el wallpaper. matugen saca la paleta (scripts/theme.py la calcula y escribe
// ~/.cache/stixshell/theme.json, que lee Theme.qml, y los archivos de Hyprland, hyprlock, kitty y GTK).
// Cada cambio de wallpaper, de estilo, de color fuente o del switch pide regenerar; solo corre uno a la vez.
Singleton {
    id: store

    readonly property string script: Quickshell.shellPath("scripts/theme.py")
    readonly property string cacheFile: Quickshell.env("HOME") + "/.cache/stixshell/theme.json"
    readonly property var cfg: ST.SettingsStore.theme

    // matugen instalado
    property bool available: false
    // Ya se sabe si hay matugen y qué se aplicó la última vez
    property bool started: false
    property bool busy: false
    // Aviso corto en la fila del selector
    property string message: ""

    // Wallpaper actual y el color fuente elegido para él (0 = el más dominante)
    readonly property string image: App.Wallpaper.current
    readonly property int index: Math.min(3, cfg.sources[image] ?? 0)
    // Modo de color: scheme = toda la shell con la paleta del wallpaper · accent = solo el acento sale del wallpaper ·
    // custom = solo el acento, el color elegido. Sin modo guardado se deduce de lo de antes (dynamic y tint).
    readonly property string mode: cfg.mode !== "" ? cfg.mode : (!cfg.dynamic ? "custom" : (cfg.tint === "neutral" ? "accent" : "scheme"))
    readonly property string color: cfg.color
    // Con el acento propio no hace falta matugen ni wallpaper
    readonly property bool dynamic: mode !== "custom"
    readonly property string scheme: cfg.scheme
    readonly property string tint: cfg.tint === "vivid" ? "vivid" : "tinted"
    // Los colores fuente que matugen encuentra en el wallpaper actual (hasta 4, "#rrggbb")
    property var sources: []

    // Lo que describe lo ya aplicado y lo que se quiere (cambian a la vez que el wallpaper o los ajustes)
    property string appliedKey: ""
    property bool pending: false
    readonly property string wantedKey: keyFor(mode, image, scheme, index, tint, color)

    // Lo que identifica un resultado aplicado (para no regenerar lo que ya está)
    function keyFor(m, img, sch, idx, tnt, col) {
        if (m === "custom")
            return "custom|" + col;
        if (img === "")
            return "wait";
        if (m === "accent")
            return "accent|" + img + "|" + idx;
        return "scheme|" + img + "|" + sch + "|" + idx + "|" + tnt;
    }

    function setMode(m) {
        if (m === "scheme" || m === "accent" || m === "custom")
            cfg.mode = m;
    }
    function setColor(hex) {
        if (/^#[0-9a-fA-F]{6}$/.test(hex))
            cfg.color = hex.toLowerCase();
    }
    function setDynamic(on) {
        setMode(on ? "scheme" : "custom");
    }
    function setScheme(id) {
        cfg.scheme = id;
    }
    function setTint(id) {
        cfg.tint = id;
    }
    // El color fuente se recuerda por wallpaper (se reasigna el objeto entero para que se guarde)
    function setSource(i) {
        if (image === "")
            return;
        const s = Object.assign({}, cfg.sources);
        s[image] = i;
        cfg.sources = s;
    }

    // Gotero: toma un color de la pantalla (hyprpicker) y lo pone de acento propio
    property bool eyedropping: false
    function pickColor() {
        if (eyedropping)
            return;
        eyedropping = true;
        run_dropper.running = true;
    }
    Process {
        id: run_dropper
        command: ["hyprpicker", "-f", "hex", "-l", "-b", "-q"]
        stdout: StdioCollector {
            id: dropOut
        }
        onExited: function (code) {
            store.eyedropping = false;
            const hex = dropOut.text.trim();
            if (code === 0 && /^#[0-9a-fA-F]{6}$/.test(hex)) {
                store.setColor(hex);
                store.setMode("custom");
            } else if (code === 127) {
                store.say("No se pudo usar el gotero (hyprpicker)");
            }
        }
    }

    function say(text) {
        message = text;
        messageTimer.restart();
    }
    Timer {
        id: messageTimer
        interval: 4000
        onTriggered: store.message = ""
    }

    // Vuelve a pedir la paleta aunque nada haya cambiado
    function regenerate() {
        appliedKey = "";
        check();
    }

    function check() {
        // Hasta saber si hay matugen y qué se aplicó la última vez no se decide nada; el wallpaper se lee del
        // disco un instante después de arrancar
        if (!started || wantedKey === "wait" || (mode !== "custom" && !available))
            return;
        if (wantedKey === appliedKey) {
            if (lastFile && lastFile.image === image)
                sources = lastFile.sources ?? [];
            return;
        }
        debounce.restart();
    }

    Timer {
        id: debounce
        interval: App.Config.theme.debounce
        onTriggered: store.run()
    }

    Connections {
        target: App.Wallpaper
        function onCurrentChanged() {
            store.check();
        }
    }
    Connections {
        target: store.cfg
        function onModeChanged() {
            store.check();
        }
        function onColorChanged() {
            store.check();
        }
        function onDynamicChanged() {
            store.check();
        }
        function onSchemeChanged() {
            store.check();
        }
        function onSourcesChanged() {
            store.check();
        }
        function onTintChanged() {
            store.check();
        }
    }

    // ── Generar ──
    property string runningKey: ""

    function run() {
        if (busy) {
            pending = true;
            return;
        }
        if (wantedKey === appliedKey)
            return;
        runningKey = wantedKey;
        busy = true;
        const cmd = ["python3", script, "apply", "--mode", mode];
        if (mode === "custom")
            cmd.push("--color", color.slice(1));
        else if (mode === "accent")
            cmd.push("--image", image, "--index", String(index));
        else
            cmd.push("--image", image, "--scheme", scheme, "--index", String(index), "--tint", tint);
        proc.command = cmd;
        proc.running = true;
    }

    Process {
        id: proc
        stdout: StdioCollector {
            id: out
        }
        onExited: function (code) {
            store.busy = false;
            let r = null;
            try {
                r = JSON.parse(out.text);
            } catch (err) {
                r = null;
            }
            if (code === 0 && r && r.ok) {
                store.appliedKey = store.runningKey;
                store.lastFile = null;
                store.sources = r.sources ?? [];
            } else {
                // Se conservan los colores anteriores; sin esto, no se reintentaría en bucle
                store.appliedKey = store.runningKey;
                store.say((r && r.error) ? r.error : "No se pudieron generar los colores");
            }
            if (store.pending) {
                store.pending = false;
                store.check();
            }
        }
    }

    // ── Al arrancar ──
    // matugen instalado y lo último aplicado (theme.json): solo se regenera si no coincide con lo actual
    Process {
        running: true
        command: ["sh", "-c", "command -v matugen"]
        onExited: function (code) {
            store.available = code === 0;
            store.readApplied();
            store.started = true;
            store.check();
        }
    }

    FileView {
        id: applied
        path: store.cacheFile
        blockLoading: true
        printErrors: false
    }

    // Lo último que escribió scripts/theme.py ({ image, scheme, index, sources, shell })
    property var lastFile: null

    function readApplied() {
        try {
            lastFile = JSON.parse(applied.text());
            // Un archivo de antes de los modos (sin `mode`) se vuelve a generar
            appliedKey = lastFile.mode ? keyFor(lastFile.mode, lastFile.image, lastFile.scheme, lastFile.index, lastFile.tint ?? "tinted", lastFile.color ?? "") : "";
        } catch (err) {
            lastFile = null;
            appliedKey = "";
        }
    }

    // ── IPC ──
    // qs ipc call stixshell@theme regen|toggle   ·   mode scheme|accent|custom   ·   color <rrggbb>   ·   scheme <id>   ·   tint tinted|vivid
    IpcHandler {
        target: "stixshell@theme"
        function regen(): void {
            store.regenerate();
        }
        // Alterna entre «colores del wallpaper» y «acento propio»
        function toggle(): void {
            store.setMode(store.mode === "scheme" ? "custom" : "scheme");
        }
        function mode(m: string): void {
            store.setMode(m);
        }
        // Gotero: toma un color de la pantalla
        function pick(): void {
            store.pickColor();
        }
        function color(hex: string): void {
            store.setColor(hex.startsWith("#") ? hex : "#" + hex);
        }
        function scheme(id: string): void {
            store.setScheme(id);
        }
        function tint(id: string): void {
            store.setTint(id);
        }
    }
}
