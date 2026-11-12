pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../notify/" as N
import "../settings/" as ST
import "../../" as App

// Grabador de pantalla: monitor o región, con audio interno y/o micrófono. wf-recorder corre aparte de la
// shell (scripts/screen-record.py), así que una recarga de qs no corta la grabación: al arrancar, la shell
// pregunta el estado y retoma el contador.
//
// Fases: idle → countdown → starting → recording → saving → idle
// La región se elige antes, con el selector de la shell (RegionSelector); mientras tanto `picking` es true.
Singleton {
    id: store

    readonly property string script: Quickshell.shellPath("scripts/screen-record.py")
    readonly property string pickScript: Quickshell.shellPath("scripts/pick-folder.py")

    property string phase: "idle"
    readonly property bool active: phase !== "idle"
    // Grabando o guardando: las acciones de sesión (suspender, apagar…) esperan a que se guarde
    readonly property bool busy: phase === "starting" || phase === "recording" || phase === "saving"
    readonly property bool showPill: active

    // El menú de la isla central
    signal openMenu
    signal closeMenu

    // ── Lo que se elige en el menú (se recuerda en settings.json) ──
    readonly property var cfg: ST.SettingsStore.recorder
    readonly property bool internal: cfg.internal
    readonly property bool mic: cfg.mic

    function hasScreen(name) {
        for (let i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === name)
                return true;
        return false;
    }

    // Monitor o "region"; si el guardado ya no está conectado, el primero
    readonly property string target: cfg.target === "region" || hasScreen(cfg.target) ? cfg.target : (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "region")

    function setTarget(name) {
        cfg.target = name;
    }
    function setInternal(on) {
        cfg.internal = on;
    }
    function setMic(on) {
        cfg.mic = on;
    }

    // ── Región ──
    // El selector (components/widgets/recorder/RegionSelector.qml) está abierto
    property bool picking: false
    // "menu": al aceptar vuelve el menú; "record": al aceptar empieza la cuenta regresiva
    property string pickThen: "menu"
    // Coordenadas globales del escritorio, pares (el codificador no admite tamaños impares)
    property var region: null
    readonly property string regionText: region ? region.w + " × " + region.h : ""
    readonly property string regionGeometry: region ? region.x + "," + region.y + " " + region.w + "x" + region.h : ""

    function pickRegion(then) {
        if (phase !== "idle" || picking)
            return;
        setTarget("region");
        pickThen = then;
        closeMenu();
        picking = true;
    }

    function acceptRegion(screenName, x, y, w, h) {
        region = {
            screen: screenName,
            x: Math.round(x),
            y: Math.round(y),
            w: Math.max(2, Math.floor(w / 2) * 2),
            h: Math.max(2, Math.floor(h / 2) * 2)
        };
        picking = false;
        if (pickThen === "record") {
            geometry = regionGeometry;
            startCountdown();
        } else {
            openMenu();
        }
    }

    function cancelPick() {
        if (!picking)
            return;
        picking = false;
        openMenu();
    }

    // ── Carpeta de destino ──
    property string videosDir: Quickshell.env("HOME") + "/Vídeos"
    readonly property string defaultFolder: videosDir + "/" + App.Config.recorder.folderName
    readonly property string folder: cfg.folder !== "" ? cfg.folder : defaultFolder
    // Solo el nombre ("Grabaciones"); la ruta completa va de tooltip
    readonly property string folderName: {
        const p = folder.replace(/\/+$/, "");
        return p.substring(p.lastIndexOf("/") + 1) || p;
    }

    Process {
        running: true
        command: ["xdg-user-dir", "VIDEOS"]
        stdout: StdioCollector {
            onStreamFinished: {
                const d = text.trim();
                if (d !== "" && d !== Quickshell.env("HOME"))
                    store.videosDir = d;
            }
        }
    }

    // Diálogo de carpetas (GTK): la isla se cierra mientras está abierto y el menú vuelve al terminar
    function pickFolder() {
        closeMenu();
        pickProc.command = ["python3", pickScript, folder, "Carpeta de las grabaciones"];
        pickProc.running = true;
    }

    Process {
        id: pickProc
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p !== "")
                    store.cfg.folder = p;
                store.openMenu();
            }
        }
    }

    // ── Tiempo grabado ──
    property real startMs: 0
    property real now: Date.now()
    readonly property int elapsed: Math.max(0, Math.floor((now - startMs) / 1000))

    function format(sec) {
        const h = Math.floor(sec / 3600);
        const m = Math.floor((sec % 3600) / 60);
        const s = sec % 60;
        const ss = (s < 10 ? "0" : "") + s;
        if (h > 0)
            return h + ":" + (m < 10 ? "0" : "") + m + ":" + ss;
        return m + ":" + ss;
    }
    readonly property string elapsedText: format(elapsed)

    Timer {
        interval: 1000
        repeat: true
        running: store.phase === "recording" || store.phase === "starting"
        triggeredOnStart: true
        onTriggered: store.now = Date.now()
    }

    // Revisa que wf-recorder siga vivo (si murió solo: disco lleno, etc.)
    Timer {
        interval: App.Config.recorder.checkInterval
        repeat: true
        running: store.phase === "recording"
        onTriggered: store.refreshStatus()
    }

    // ── Flujo: elegir región → cuenta regresiva → grabar ──
    property int count: 0
    property string geometry: ""
    property string file: ""
    property bool dndBefore: false
    property bool retried: false
    // Acción pendiente (suspender, apagar…) que espera a que se guarde el video
    property var afterSaved: null

    function begin() {
        if (phase !== "idle" || picking)
            return;
        if (target === "region" && !region) {
            // Sin región elegida: se elige ahora y, al aceptar, empieza a grabar
            pickRegion("record");
            return;
        }
        closeMenu();
        geometry = target === "region" ? regionGeometry : "";
        startCountdown();
    }

    function startCountdown() {
        const n = App.Config.recorder.countdown;
        if (n <= 0) {
            launch(false);
            return;
        }
        count = n;
        phase = "countdown";
        countTimer.restart();
    }

    // Super+G o clic en el contador: cancela la elección o la cuenta regresiva, o detiene y guarda
    function stopOrCancel() {
        if (picking)
            cancelPick();
        else if (phase === "countdown")
            cancel();
        else if (phase === "recording")
            stop();
    }

    function cancel() {
        if (phase === "countdown") {
            countTimer.stop();
            phase = "idle";
        }
    }

    Timer {
        id: countTimer
        interval: 1000
        repeat: true
        onTriggered: {
            store.count--;
            if (store.count <= 0) {
                countTimer.stop();
                store.launch(false);
            }
        }
    }

    function launch(fallback) {
        const c = App.Config.recorder;
        if (!fallback) {
            retried = false;
            // Mientras graba no salen popups en el video; al terminar vuelve como estaba
            dndBefore = N.NotificationStore.dnd;
            N.NotificationStore.setDnd(true);
            file = folder + "/" + Qt.formatDateTime(new Date(), c.filePattern) + ".mp4";
        }
        retried = fallback;
        phase = "starting";
        startMs = Date.now();
        now = startMs;

        const cmd = ["python3", script, "start", "--file", file, "--fps", String(c.fps), "--device", c.device, "--encoder", fallback ? c.fallbackEncoder : c.encoder];
        if (geometry !== "")
            cmd.push("--geometry", geometry);
        else
            cmd.push("--output", target);
        if (internal)
            cmd.push("--internal");
        if (mic)
            cmd.push("--mic");
        if (dndBefore)
            cmd.push("--dnd-before");
        startProc.command = cmd;
        startProc.running = true;
    }

    Process {
        id: startProc
        stderr: StdioCollector {
            id: startErr
        }
        onExited: function (code) {
            if (code === 0) {
                store.phase = "recording";
                store.refreshStatus();
                if (store.afterSaved)
                    store.stop();
                return;
            }
            // VA-API falló: se reintenta una vez con la CPU
            if (!store.retried && App.Config.recorder.encoder !== App.Config.recorder.fallbackEncoder) {
                store.launch(true);
                return;
            }
            store.fail(startErr.text.trim());
        }
    }

    function fail(msg) {
        restoreDnd();
        phase = "idle";
        Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Grabador", "-i", "dialog-error", "No se pudo grabar", msg || "wf-recorder no arrancó. ¿Está instalado?"]);
        runAfterSaved();
    }

    function restoreDnd() {
        N.NotificationStore.setDnd(dndBefore);
    }

    // ── Detener ──
    function stop() {
        if (phase !== "recording")
            return;
        phase = "saving";
        stopProc.running = true;
    }

    // Para suspender, cerrar sesión, reiniciar o apagar: primero se guarda el video
    function whenSaved(fn) {
        afterSaved = fn;
        if (phase === "recording")
            stop();
    }

    function runAfterSaved() {
        if (!afterSaved)
            return;
        const f = afterSaved;
        afterSaved = null;
        f();
    }

    Process {
        id: stopProc
        command: ["python3", store.script, "stop"]
        stdout: StdioCollector {
            onStreamFinished: store.saved(text.trim())
        }
    }

    function saved(path) {
        const dur = elapsedText;
        restoreDnd();
        phase = "idle";
        if (path !== "")
            notifySaved(path, dur);
        runAfterSaved();
    }

    // ── Aviso con Abrir y Carpeta ──
    property string lastFile: ""

    function notifySaved(path, dur) {
        lastFile = path;
        const name = path.substring(path.lastIndexOf("/") + 1);
        if (notifyProc.running) {
            Quickshell.execDetached(["notify-send", "-a", "Grabador", "-i", "video-x-generic", "Grabación guardada", name + " · " + dur]);
            return;
        }
        notifyProc.command = ["notify-send", "-a", "Grabador", "-i", "video-x-generic", "-A", "open=Abrir", "-A", "folder=Carpeta", "Grabación guardada", name + " · " + dur];
        notifyProc.running = true;
    }

    // El reproductor de video predeterminado (gio abre con la app asociada al tipo, p. ej. mpv)
    function openVideo(path) {
        Quickshell.execDetached(["gio", "open", path]);
    }

    // El gestor de archivos predeterminado, con el video seleccionado (org.freedesktop.FileManager1).
    // No se usa xdg-open: en este equipo kitty-open queda como app de carpetas y las abriría en la terminal.
    function showInFolder(path) {
        const dir = path.substring(0, path.lastIndexOf("/"));
        Quickshell.execDetached(["sh", "-c", 'gdbus call --session --dest org.freedesktop.FileManager1 --object-path /org/freedesktop/FileManager1 --method org.freedesktop.FileManager1.ShowItems "[\"$1\"]" "" >/dev/null 2>&1 || gio open "$2"', "_", encodeURI("file://" + path), dir]);
    }

    Process {
        id: notifyProc
        stdout: StdioCollector {
            onStreamFinished: {
                const a = text.trim();
                if (a === "open")
                    store.openVideo(store.lastFile);
                else if (a === "folder")
                    store.showInFolder(store.lastFile);
            }
        }
    }

    // ── Estado de wf-recorder (al arrancar la shell, tras empezar y cada pocos segundos grabando) ──
    function refreshStatus() {
        if (!statusProc.running)
            statusProc.running = true;
    }

    function onStatus(text) {
        let st = {};
        try {
            st = JSON.parse(text);
        } catch (err) {
            return;
        }
        if (st.alive) {
            startMs = st.start;
            now = Date.now();
            file = st.file;
            dndBefore = !!st.dndBefore;
            if (phase === "idle" || phase === "starting")
                phase = "recording";
        } else if (st.dead || phase === "recording") {
            // wf-recorder murió solo (disco lleno, se cerró…): se limpia todo
            if (phase === "idle" || phase === "recording") {
                if (st.dead)
                    dndBefore = !!st.dndBefore;
                restoreDnd();
                const was = phase === "recording";
                phase = "idle";
                if (was)
                    Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Grabador", "-i", "dialog-error", "La grabación terminó sola", st.file || ""]);
                runAfterSaved();
            }
        }
    }

    Process {
        id: statusProc
        command: ["python3", store.script, "status"]
        stdout: StdioCollector {
            onStreamFinished: store.onStatus(text)
        }
    }

    Component.onCompleted: refreshStatus()
}
