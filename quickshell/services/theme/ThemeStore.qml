pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../settings/" as ST
import "../../" as App

// Colores según el wallpaper. scripts/theme.py saca los colores reales de la imagen (Pillow), arma sus combinaciones
// de fondo y acento («Lila + verde») y con la elegida calcula los colores (escribe ~/.cache/stixshell/theme.json,
// que lee Theme.qml, y los archivos de Hyprland, hyprlock, kitty y GTK).
// Cada cambio de wallpaper, de combinación, de intensidad o de apps pide regenerar; solo corre uno a la vez.
Singleton {
    id: store

    readonly property string script: Quickshell.shellPath("scripts/theme.py")
    readonly property string cacheFile: Quickshell.env("HOME") + "/.cache/stixshell/theme.json"
    readonly property var cfg: ST.SettingsStore.theme

    // Pillow instalado (saca los colores de la imagen)
    property bool available: false
    // Ya se sabe si hay Pillow y qué se aplicó la última vez
    property bool started: false
    property bool busy: false
    // Aviso corto en la fila del selector
    property string message: ""

    // Wallpaper actual
    readonly property string image: App.Wallpaper.current
    // Modo de color: scheme = fondo y acento de la imagen (una combinación) · custom = solo el acento, el que elijas.
    // Sin modo guardado se deduce de lo de antes (dynamic); «accent» (el modo de antes) se migra en check().
    readonly property string mode: cfg.mode === "custom" || (cfg.mode === "" && !cfg.dynamic) ? "custom" : "scheme"
    readonly property string color: cfg.color
    // Con el acento propio no hace falta Pillow ni wallpaper
    readonly property bool dynamic: mode !== "custom"
    // Qué tan teñido sale el fondo: tinted (Sutil) | vivid (Intensa)
    readonly property string tint: cfg.intensity === "tinted" ? "tinted" : "vivid"
    // Las apps que también toman el fondo, ordenadas (así se compara con lo que escribió theme.py)
    readonly property string apps: [cfg.apps.gtk ? "gtk" : "", cfg.apps.kitty ? "kitty" : ""].filter(a => a !== "").join(",")
    // La combinación elegida para este wallpaper ("" = la primera)
    readonly property string wantedCombo: (cfg.combos ?? {})[image] ?? ""
    // Las combinaciones del wallpaper actual ({ id, bg, accent, name, preview }) y la que quedó aplicada
    property var combos: []
    property string combo: ""
    readonly property var current: combos.find(c => c.id === combo) ?? null
    // Los ~12 colores de la imagen
    property var palette: []

    // Lo que describe lo ya aplicado y lo que se quiere (cambian a la vez que el wallpaper o los ajustes)
    property string appliedKey: ""
    property bool pending: false
    property bool migrating: false
    readonly property string wantedKey: keyFor(mode, image, wantedCombo, tint, apps, color)

    // Lo que identifica un resultado aplicado (para no regenerar lo que ya está)
    function keyFor(m, img, cmb, tnt, aps, col) {
        if (m === "custom")
            return "custom|" + col;
        if (img === "")
            return "wait";
        return "scheme|" + img + "|" + cmb + "|" + tnt + "|" + aps;
    }

    function setMode(m) {
        if (m === "scheme" || m === "custom")
            cfg.mode = m;
    }
    function setColor(hex) {
        if (/^#[0-9a-fA-F]{6}$/.test(hex))
            cfg.color = hex.toLowerCase();
    }
    function setDynamic(on) {
        setMode(on ? "scheme" : "custom");
    }
    function setTint(id) {
        if (id === "tinted" || id === "vivid")
            cfg.intensity = id;
    }
    function setApp(name, on) {
        if (name === "kitty" || name === "gtk")
            cfg.apps[name] = on;
    }
    // La combinación se recuerda por wallpaper (se reasigna el objeto entero para que se guarde)
    function setCombo(id) {
        if (image === "" || !combos.some(c => c.id === id))
            return;
        const c = Object.assign({}, cfg.combos);
        c[image] = id;
        cfg.combos = c;
        if (cfg.mode !== "scheme")
            cfg.mode = "scheme";
    }
    // Pasa a la siguiente (o anterior) combinación
    function stepCombo(d) {
        if (combos.length === 0)
            return;
        const i = Math.max(0, combos.findIndex(c => c.id === combo));
        setCombo(combos[(i + d + combos.length) % combos.length].id);
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
        // Hasta saber si hay Pillow y qué se aplicó la última vez no se decide nada; el wallpaper se lee del
        // disco un instante después de arrancar
        if (!started || wantedKey === "wait" || (mode !== "custom" && !available))
            return;
        // El modo «Acento del wallpaper» de antes pasa a ser la combinación con el fondo del sistema
        if (cfg.mode === "accent") {
            // Cada cambio que se guarda vuelve a llamar a check(): sin el aviso, esto se llamaría a sí mismo
            if (!migrating) {
                migrating = true;
                const c = Object.assign({}, cfg.combos);
                if (c[image] === undefined)
                    c[image] = "neutral";
                cfg.combos = c;
                cfg.mode = "scheme";
                migrating = false;
                check();
            }
            return;
        }
        if (wantedKey === appliedKey) {
            if (lastFile && lastFile.image === image && combos.length === 0)
                useResult(lastFile);
            return;
        }
        debounce.restart();
    }

    function useResult(r) {
        combos = r.combos ?? [];
        palette = r.palette ?? [];
        combo = r.combo ?? "";
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
        function onIntensityChanged() {
            store.check();
        }
        function onCombosChanged() {
            store.check();
        }
    }
    Connections {
        target: store.cfg.apps
        function onKittyChanged() {
            store.check();
        }
        function onGtkChanged() {
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
        else {
            cmd.push("--image", image, "--tint", tint, "--apps", apps);
            if (wantedCombo !== "")
                cmd.push("--combo", wantedCombo);
        }
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
                // Con el acento propio se conservan las combinaciones del wallpaper (para cuando se vuelva)
                if (store.mode !== "custom")
                    store.useResult(r);
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
    // Pillow instalado y lo último aplicado (theme.json): solo se regenera si no coincide con lo actual
    Process {
        running: true
        command: ["python3", "-c", "import PIL"]
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

    // Lo último que escribió scripts/theme.py ({ image, combo, wanted, tint, apps, palette, combos, shell })
    property var lastFile: null

    function readApplied() {
        try {
            lastFile = JSON.parse(applied.text());
            // Un archivo de antes de las combinaciones (sin `wanted`) se vuelve a generar
            appliedKey = lastFile.mode && lastFile.wanted !== undefined ? keyFor(lastFile.mode, lastFile.image, lastFile.wanted, lastFile.tint ?? "vivid", (lastFile.apps ?? []).join(","), lastFile.color ?? "") : "";
        } catch (err) {
            lastFile = null;
            appliedKey = "";
        }
    }

    // ── IPC ──
    // qs ipc call stixshell@theme regen|toggle   ·   mode scheme|custom   ·   color <rrggbb>   ·   tint tinted|vivid
    //   combo <n|id> (la combinación n de 1 a 6, o su id)   ·   next|prev (otra combinación)
    IpcHandler {
        target: "stixshell@theme"
        function regen(): void {
            store.regenerate();
        }
        // Alterna entre «del wallpaper» y «acento propio»
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
        function tint(id: string): void {
            store.setTint(id);
        }
        function combo(which: string): void {
            if (/^[0-9]{1,2}$/.test(which)) {
                const c = store.combos[parseInt(which) - 1];
                if (c)
                    store.setCombo(c.id);
            } else {
                store.setCombo(which);
            }
        }
        function next(): void {
            store.stepCombo(1);
        }
        function prev(): void {
            store.stepCombo(-1);
        }
    }
}
