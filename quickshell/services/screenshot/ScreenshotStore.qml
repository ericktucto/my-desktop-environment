pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../panels/" as P
import "../region/" as RG
import "../lock/" as LK
import "../settings/" as ST
import "../share/" as SH
import "../../" as App

// Capturador de pantalla (Impr Pant, Super+Shift+S o la casilla Captura del centro de control).
// grim congela cada monitor (scripts/screenshot.py) y el capturador (components/widgets/screenshot) muestra esa
// imagen quieta: ahí se marca el área, o se elige una ventana o la pantalla, y con el Editor encendido se anota.
//
// Fases: idle → countdown (retardo) → freezing → open → saving → idle
Singleton {
    id: store

    readonly property string script: Quickshell.shellPath("scripts/screenshot.py")
    readonly property string tmpDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/stixshell/shot"
    readonly property var conf: App.Config.screenshot

    property string phase: "idle"
    readonly property bool active: phase !== "idle"
    // El capturador está en pantalla
    readonly property bool shown: phase === "open"
    property int count: 0

    // ── Lo que se elige en la barra (se recuerda en settings.json) ──
    readonly property var cfg: ST.SettingsStore.screenshot
    readonly property string mode: cfg.mode
    readonly property int delay: cfg.delay
    // Se anota con el Editor encendido, y siempre al volver a editar una imagen guardada
    readonly property bool editorOn: cfg.editor || editSource !== ""

    function setMode(m) {
        cfg.mode = m;
    }
    function setEditor(on) {
        cfg.editor = on;
    }
    function cycleDelay() {
        const d = conf.delays;
        setDelay(d[(Math.max(0, d.indexOf(cfg.delay)) + 1) % d.length]);
    }
    // Con 3 o 5 s dentro del capturador, se vuelve a capturar en ese momento (para abrir un menú, por ejemplo)
    function setDelay(n) {
        cfg.delay = n;
        if (phase === "open" && editSource === "" && n > 0) {
            discard();
            startCountdown();
        }
    }

    // ── Lo congelado ──
    // monitor → ruta del PNG; ventanas visibles ({ monitor, x, y, w, h, class, title }) de arriba abajo
    property var frames: ({})
    property var windows: []
    // Monitor donde aparece la barra de modos (el enfocado al abrir)
    property string barScreen: ""
    // Monitor donde está el área elegida (solo uno a la vez)
    property string selScreen: ""
    // Imagen que se está editando (aviso [Editar]); "" = captura normal
    property string editSource: ""

    // El capturador pide una acción a la selección ("copy" | "save" | "both"): la atiende el monitor que la tenga
    signal actionRequested(string action)
    // Mensaje corto sobre la barra ("Esc otra vez para descartar")
    property string hintText: ""

    function say(text) {
        hintText = text;
        hintTimer.restart();
    }
    Timer {
        id: hintTimer
        interval: 2500
        onTriggered: store.hintText = ""
    }

    // ── Carpeta de destino ──
    property string picturesDir: Quickshell.env("HOME") + "/Imágenes"
    readonly property string folder: cfg.folder !== "" ? cfg.folder : picturesDir + "/" + conf.folderName

    Process {
        running: true
        command: ["xdg-user-dir", "PICTURES"]
        stdout: StdioCollector {
            onStreamFinished: {
                const d = text.trim();
                if (d !== "" && d !== Quickshell.env("HOME"))
                    store.picturesDir = d;
            }
        }
    }

    // ── Abrir ──
    // `forced`: "area", "window" o "screen" (IPC); "" usa el último modo
    function start(forced) {
        if (phase !== "idle" || RG.RegionStore.picking || LK.LockStore.locked)
            return;
        if (forced)
            cfg.mode = forced;
        editSource = "";
        if (cfg.delay > 0) {
            P.PanelStore.closeAll();
            startCountdown();
            return;
        }
        // La isla (casilla del centro de control) se cierra y se espera a que termine su animación
        const wait = P.PanelStore.anyExpanded ? conf.closeDelay : 0;
        if (wait > 0)
            P.PanelStore.closeAll();
        phase = "freezing";
        freezeTimer.interval = Math.max(1, wait);
        freezeTimer.restart();
    }

    function startCountdown() {
        count = cfg.delay;
        phase = "countdown";
        countTimer.restart();
    }

    Timer {
        id: countTimer
        interval: 1000
        repeat: true
        onTriggered: {
            store.count--;
            if (store.count <= 0) {
                countTimer.stop();
                // La pill del retardo se oculta antes de congelar, así no sale en la captura
                store.phase = "freezing";
                freezeTimer.interval = store.conf.hideDelay;
                freezeTimer.restart();
            }
        }
    }

    Timer {
        id: freezeTimer
        onTriggered: store.freeze()
    }

    // Impr Pant con el capturador abierto o contando lo cancela
    function toggle() {
        if (active)
            cancel();
        else
            start("");
    }

    function cancel() {
        countTimer.stop();
        freezeTimer.stop();
        if (phase === "saving")
            return;
        finish();
    }

    // Vuelve a empezar sin cerrar del todo (el retardo dentro del capturador)
    function discard() {
        AnnotationStore.reset();
        frames = {};
        windows = [];
        selScreen = "";
        phase = "idle";
    }

    // Edita una imagen guardada: se muestra centrada con el Editor encendido
    function edit(path) {
        if (phase !== "idle" || RG.RegionStore.picking || LK.LockStore.locked)
            return;
        if (path === "")
            return;
        P.PanelStore.closeAll();
        // Ahí se escribe lo anotado antes de guardarlo (al capturar, lo crea el congelado)
        Quickshell.execDetached(["mkdir", "-p", tmpDir]);
        editSource = path;
        barScreen = Hyprland.focusedMonitor?.name ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
        phase = "open";
    }

    // ── Congelar ──
    function freeze() {
        const names = Quickshell.screens.map(s => s.name);
        freezeProc.command = ["python3", script, "freeze", tmpDir].concat(names);
        freezeProc.running = true;
    }

    Process {
        id: freezeProc
        stdout: StdioCollector {
            id: freezeOut
        }
        stderr: StdioCollector {
            id: freezeErr
        }
        onExited: function (code) {
            if (store.phase !== "freezing")
                return;
            let r = null;
            try {
                r = JSON.parse(freezeOut.text);
            } catch (err) {
                r = null;
            }
            if (code !== 0 || !r) {
                store.fail("No se pudo capturar la pantalla", freezeErr.text.trim());
                return;
            }
            const f = {};
            for (const s of Quickshell.screens)
                f[s.name] = store.tmpDir + "/" + s.name + ".png";
            store.frames = f;
            store.windows = r.windows;
            store.barScreen = r.focused;
            // Con un solo monitor, "Pantalla" sin Editor captura al instante
            if (store.mode === "screen" && !store.editorOn && Quickshell.screens.length === 1) {
                store.deliver(f[Quickshell.screens[0].name], null, "both");
                return;
            }
            store.phase = "open";
        }
    }

    // ── Entregar: guardar y/o copiar ──
    // `src`: PNG ya listo (con `crop` = [x, y, w, h] en px reales para recortarlo, o null)
    // `action`: "both" | "copy" | "save"
    property string lastFile: ""

    function destPath() {
        if (editSource !== "")
            return editSource.replace(/\.png$/i, "") + " editada.png";
        return folder + "/" + Qt.formatDateTime(new Date(), conf.filePattern) + ".png";
    }

    function deliver(src, crop, action) {
        phase = "saving";
        AnnotationStore.reset();
        const save = action !== "copy";
        const cmd = ["python3", script, "deliver", src];
        if (crop)
            cmd.push("--crop", crop.map(v => Math.round(v)).join(","));
        if (save)
            cmd.push("--dest", destPath());
        if (action !== "save")
            cmd.push("--copy");
        deliverProc.copied = action !== "save";
        deliverProc.command = cmd;
        deliverProc.running = true;
    }

    Process {
        id: deliverProc
        property bool copied: false
        stdout: StdioCollector {
            id: deliverOut
        }
        stderr: StdioCollector {
            id: deliverErr
        }
        onExited: function (code) {
            let r = null;
            try {
                r = JSON.parse(deliverOut.text);
            } catch (err) {
                r = null;
            }
            if (code !== 0 || !r) {
                store.fail("No se pudo guardar la captura", deliverErr.text.trim());
                return;
            }
            store.finish();
            store.notifyDone(r.dest, r.w, r.h, copied);
        }
    }

    // Cierra todo y borra lo temporal
    function finish() {
        countTimer.stop();
        freezeTimer.stop();
        AnnotationStore.reset();
        phase = "idle";
        frames = {};
        windows = [];
        editSource = "";
        selScreen = "";
        filePicking = false;
        Quickshell.execDetached(["rm", "-rf", tmpDir]);
    }

    function fail(title, detail) {
        finish();
        Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Capturas", "-i", "dialog-error", title, detail || ""]);
    }

    // ── Aviso con Abrir, Carpeta y Editar ──
    function notifyDone(dest, w, h, copied) {
        const size = w + " × " + h;
        if (dest === "") {
            Quickshell.execDetached(["notify-send", "-a", "Capturas", "-i", "camera-photo", "Captura copiada al portapapeles", size]);
            return;
        }
        lastFile = dest;
        const name = dest.substring(dest.lastIndexOf("/") + 1);
        const title = copied ? "Captura guardada y copiada" : "Captura guardada";
        if (notifyProc.running) {
            Quickshell.execDetached(["notify-send", "-a", "Capturas", "-i", dest, title, name + " · " + size]);
            return;
        }
        notifyProc.command = ["notify-send", "-a", "Capturas", "-i", dest, "-A", "open=Abrir", "-A", "folder=Carpeta", "-A", "edit=Editar", title, name + " · " + size];
        notifyProc.running = true;
    }

    Process {
        id: notifyProc
        stdout: StdioCollector {
            onStreamFinished: {
                const a = text.trim();
                if (a === "open")
                    SH.ShareStore.openFile(store.lastFile);
                else if (a === "folder")
                    SH.ShareStore.showInFolder(store.lastFile);
                else if (a === "edit")
                    store.edit(store.lastFile);
            }
        }
    }

    // ── Stickers propios (PNG y SVG de una carpeta, o uno elegido en el diálogo de archivos) ──
    readonly property string stickersDir: Quickshell.env("HOME") + "/.config/stixshell/stickers"
    property var stickerFiles: []
    // El diálogo de GTK está abierto: el capturador se esconde un momento (si no, tapa el diálogo)
    property bool filePicking: false
    signal stickerPicked(string path)

    function refreshStickers() {
        if (!listProc.running)
            listProc.running = true;
    }

    Process {
        id: listProc
        command: ["sh", "-c", 'find "$1" -maxdepth 1 -type f \\( -iname "*.png" -o -iname "*.svg" -o -iname "*.webp" -o -iname "*.jpg" -o -iname "*.jpeg" \\) 2>/dev/null | sort', "_", store.stickersDir]
        stdout: StdioCollector {
            onStreamFinished: store.stickerFiles = text.split("\n").filter(l => l !== "")
        }
    }

    function pickSticker() {
        if (filePicking)
            return;
        filePicking = true;
        pickProc.command = ["python3", Quickshell.shellPath("scripts/pick.py"), "file", Quickshell.env("HOME"), "Elegir un sticker", "*.png", "*.svg", "*.webp", "*.jpg", "*.jpeg"];
        pickProc.running = true;
    }

    Process {
        id: pickProc
        stdout: StdioCollector {
            onStreamFinished: {
                store.filePicking = false;
                const p = text.trim();
                if (p !== "")
                    store.stickerPicked(p);
            }
        }
    }

    // ── IPC ──
    // qs ipc call stixshell@screenshot open|area|window|screen|cancel   ·   edit <ruta>
    IpcHandler {
        target: "stixshell@screenshot"
        function open(): void {
            store.toggle();
        }
        function area(): void {
            store.start("area");
        }
        function window(): void {
            store.start("window");
        }
        function screen(): void {
            store.start("screen");
        }
        function cancel(): void {
            store.cancel();
        }
        function edit(path: string): void {
            store.edit(path);
        }
    }

    // Lo que quedó de una sesión anterior (la shell se recargó con el capturador abierto)
    Component.onCompleted: Quickshell.execDetached(["rm", "-rf", tmpDir])
}
