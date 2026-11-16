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
    property bool busy: false
    // Aviso corto en la fila del selector
    property string message: ""

    // Wallpaper actual y el color fuente elegido para él (0 = el más dominante)
    readonly property string image: App.Wallpaper.current
    readonly property int index: Math.min(3, cfg.sources[image] ?? 0)
    readonly property bool dynamic: cfg.dynamic
    readonly property string scheme: cfg.scheme
    // Los colores fuente que matugen encuentra en el wallpaper actual (hasta 4, "#rrggbb")
    property var sources: []

    // Lo que describe lo ya aplicado y lo que se quiere (cambian a la vez que el wallpaper o los ajustes)
    property string appliedKey: ""
    property bool pending: false
    readonly property string wantedKey: dynamic && image !== "" ? image + "|" + scheme + "|" + index : "off"

    function setDynamic(on) {
        cfg.dynamic = on;
    }
    function setScheme(id) {
        cfg.scheme = id;
    }
    // El color fuente se recuerda por wallpaper (se reasigna el objeto entero para que se guarde)
    function setSource(i) {
        if (image === "")
            return;
        const s = Object.assign({}, cfg.sources);
        s[image] = i;
        cfg.sources = s;
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
        // El wallpaper se lee del disco un instante después de arrancar: hasta entonces no se decide nada
        if (!available || (dynamic && image === ""))
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
        function onDynamicChanged() {
            store.check();
        }
        function onSchemeChanged() {
            store.check();
        }
        function onSourcesChanged() {
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
        const cmd = ["python3", script, "apply", "--scheme", scheme];
        if (dynamic && image !== "")
            cmd.push("--image", image, "--index", String(index));
        else
            cmd.push("--color", App.Config.theme.fallback);
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
            if (!store.available)
                return;
            store.readApplied();
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
            appliedKey = lastFile.image ? lastFile.image + "|" + lastFile.scheme + "|" + lastFile.index : "off";
        } catch (err) {
            lastFile = null;
            appliedKey = "";
        }
    }

    // ── IPC ──
    // qs ipc call stixshell@theme regen|toggle   ·   scheme <id>
    IpcHandler {
        target: "stixshell@theme"
        function regen(): void {
            store.regenerate();
        }
        function toggle(): void {
            store.setDynamic(!store.dynamic);
        }
        function scheme(id: string): void {
            store.setScheme(id);
        }
    }
}
