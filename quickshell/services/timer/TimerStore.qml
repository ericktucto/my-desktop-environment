pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../settings/" as ST
import "../../" as App
import "../tasks/Dates.js" as Dates
import "Duration.js" as Duration

// Temporizadores y cronómetro, guardados en ~/.config/stixshell/timers.json.
// El tiempo sale de la hora real (Date.now), no de un contador: sobrevive a recargar la shell y a suspender.
// Los datos nunca se mutan: cada cambio crea objetos y arreglos nuevos para que los bindings se enteren.
//   temporizador: { id, name, total, state: running|paused|ringing, endsAt, left, created, pomo }
//   cronómetro:   { state: idle|running|paused, since, acc, laps: [total en ms de cada vuelta] }
Singleton {
    id: store

    readonly property var cfg: App.Config.timer
    readonly property var set: ST.SettingsStore.timer

    readonly property int version: 1
    property bool ready: false
    property var timers: []
    property var stopwatch: ({
            state: "idle",
            since: 0,
            acc: 0,
            laps: []
        })
    // Los últimos tiempos a medida: [{ ms, name }]
    property var recents: []

    // Hora de la última actualización (la mueve el reloj de abajo)
    property real now: Date.now()
    // Algo del cronómetro se está viendo (la pestaña abierta): se actualiza más seguido
    property bool watching: false

    // ── Lo que se ve de afuera ──
    readonly property var ringing: timers.filter(t => t.state === "ringing")
    readonly property int running: timers.filter(t => t.state === "running").length
    // El que termina primero (los que suenan van antes)
    readonly property var next: {
        const live = timers.filter(t => t.state === "running" || t.state === "ringing");
        live.sort((a, b) => (a.state === "ringing" ? 0 : 1) - (b.state === "ringing" ? 0 : 1) || a.endsAt - b.endsAt);
        return live.length > 0 ? live[0] : null;
    }
    // Mientras corre o suena un temporizador, la laptop no se suspende (IdleStore)
    readonly property bool keepAwake: timers.some(t => t.state === "running" || t.state === "ringing")
    readonly property bool swRunning: stopwatch.state === "running"
    readonly property bool swActive: stopwatch.state !== "idle"

    signal openRequested(string tab)

    function labelFor(t) {
        return t.name !== "" ? t.name : Duration.label(t.total);
    }

    // Lo que falta (ms)
    function left(t) {
        if (!t)
            return 0;
        if (t.state === "running")
            return Math.max(0, t.endsAt - now);
        if (t.state === "paused")
            return t.left;
        return 0;
    }

    function get(id) {
        return timers.find(t => t.id === id) ?? null;
    }

    function change(id, fn) {
        let hit = false;
        timers = timers.map(t => {
            if (t.id !== id)
                return t;
            hit = true;
            return Object.assign({}, t, fn(t));
        });
        if (hit)
            save();
        return hit;
    }

    // ── Temporizadores ──
    function makeId() {
        return "t" + Date.now().toString(36) + Math.floor(Math.random() * 1296).toString(36);
    }

    function add(ms, name) {
        if (!(ms > 0) || timers.length >= cfg.maxTimers)
            return "";
        const t = {
            id: makeId(),
            name: (name || "").trim(),
            total: Math.round(ms),
            state: "running",
            endsAt: Date.now() + Math.round(ms),
            left: 0,
            created: Date.now(),
            pomo: null
        };
        now = Date.now();
        timers = timers.concat([t]);
        pushRecent(t.total, t.name);
        save();
        return t.id;
    }

    // "10m té" → un temporizador nuevo. Devuelve su id, o "" si no se entiende.
    function addFromText(text) {
        const p = Duration.parse(text);
        return p ? add(p.ms, p.name) : "";
    }

    function pushRecent(ms, name) {
        // Los tiempos rápidos sin nombre ya están a un clic
        if (name === "" && cfg.presets.indexOf(ms / 60000) >= 0)
            return;
        const list = recents.filter(r => !(r.ms === ms && r.name === name));
        list.unshift({
            ms: ms,
            name: name
        });
        recents = list.slice(0, cfg.recents);
    }

    function pause(id) {
        return change(id, t => t.state === "running" ? {
                state: "paused",
                left: Math.max(0, t.endsAt - Date.now())
            } : {});
    }

    function resume(id) {
        now = Date.now();
        return change(id, t => t.state === "paused" ? {
                state: "running",
                endsAt: Date.now() + t.left
            } : {});
    }

    function toggle(id) {
        const t = get(id);
        if (!t)
            return false;
        if (t.state === "running")
            return pause(id);
        if (t.state === "paused")
            return resume(id);
        return stopAlarm(id);
    }

    // Suma tiempo; si sonaba, vuelve a correr con ese tiempo
    function extend(id, ms) {
        const t = get(id);
        if (!t)
            return false;
        now = Date.now();
        if (t.state === "ringing") {
            closeNote(id);
            return change(id, () => ({
                    state: "running",
                    total: ms,
                    endsAt: Date.now() + ms
                }));
        }
        if (t.state === "paused")
            return change(id, () => ({
                    total: t.total + ms,
                    left: t.left + ms
                }));
        return change(id, () => ({
                total: t.total + ms,
                endsAt: t.endsAt + ms
            }));
    }

    function remove(id) {
        if (!get(id))
            return false;
        closeNote(id);
        timers = timers.filter(t => t.id !== id);
        save();
        return true;
    }

    // Detener la alarma: la tarjeta se va (queda en Recientes si era a medida)
    function stopAlarm(id) {
        return remove(id);
    }

    function stopAll() {
        timers.slice().forEach(t => remove(t.id));
    }

    function pauseAll() {
        timers.forEach(t => pause(t.id));
    }

    // ── Reloj ──
    Timer {
        id: ticker
        interval: store.watching && store.swRunning ? store.cfg.stopwatchTick : store.cfg.tick
        repeat: true
        running: store.running > 0 || store.swRunning
        onTriggered: store.tick()
    }

    function tick() {
        now = Date.now();
        const due = timers.filter(t => t.state === "running" && t.endsAt <= now);
        if (due.length > 0)
            ring(due.map(t => t.id));
    }

    // ── Alarma ──
    property real ringSince: 0
    // Pasó el tiempo máximo sonando: sigue la notificación, pero ya no el sonido
    property bool quiet: false

    function ring(ids) {
        timers = timers.map(t => ids.indexOf(t.id) >= 0 ? Object.assign({}, t, {
                state: "ringing"
            }) : t);
        ringSince = Date.now();
        quiet = false;
        ids.forEach(id => notify(get(id)));
        save();
    }

    Timer {
        id: ringTimer
        interval: store.cfg.ringEvery
        repeat: true
        triggeredOnStart: true
        running: store.ringing.length > 0 && !store.quiet
        onTriggered: {
            if (Date.now() - store.ringSince >= store.cfg.ringFor * 1000) {
                store.quiet = true;
                return;
            }
            store.playSound();
        }
    }

    // id de timer → id de su notificación en el servidor
    property var notes: ({})

    function notify(t) {
        if (!t)
            return;
        const late = Date.now() - t.endsAt;
        const what = "Temporizador de " + Duration.label(t.total);
        const body = late > 5000 ? "Terminó " + Dates.ago(t.endsAt, Date.now()) + " · " + what : what;
        const p = notice.createObject(store, {
            timerId: t.id,
            command: ["notify-send", "-a", "Temporizador", "-i", "alarm-symbolic", "-u", "critical", "-p", "-t", "0", "-A", "add1=+1 min", "-A", "add5=+5 min", "-A", "stop=Detener", "¡Listo! " + labelFor(t), body]
        });
        p.running = true;
    }

    function onAction(id, action) {
        if (action === "add1")
            extend(id, 60000);
        else if (action === "add5")
            extend(id, 300000);
        else if (action === "stop")
            stopAlarm(id);
    }

    function closeNote(id) {
        const n = notes[id];
        if (!n)
            return;
        delete notes[id];
        Quickshell.execDetached(["gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications", "--object-path", "/org/freedesktop/Notifications", "--method", "org.freedesktop.Notifications.CloseNotification", n]);
    }

    // notify-send imprime el id (-p) y, al pulsar un botón, su nombre; hasta entonces sigue vivo
    Component {
        id: notice
        Process {
            id: np
            property string timerId
            property string noteId: ""
            stdout: SplitParser {
                onRead: line => {
                    const l = line.trim();
                    if (l === "")
                        return;
                    if (np.noteId === "" && /^\d+$/.test(l)) {
                        np.noteId = l;
                        store.notes[np.timerId] = l;
                        return;
                    }
                    store.onAction(np.timerId, l);
                }
            }
            onExited: {
                if (store.notes[np.timerId] === np.noteId)
                    delete store.notes[np.timerId];
                np.destroy();
            }
        }
    }

    // ── Sonido ──
    readonly property string soundPath: set.sound === "system" || set.sound === "" ? cfg.systemSound : set.sound
    property bool soundOk: false

    function setSound(value) {
        set.sound = value;
    }

    function playSound() {
        if (soundOk && !soundProc.running)
            soundProc.running = true;
    }

    function testSound() {
        playSound();
    }

    Process {
        id: soundProc
        command: ["pw-play", store.soundPath]
    }

    onSoundPathChanged: checkSound()
    function checkSound() {
        soundCheck.running = false;
        soundCheck.command = ["test", "-f", soundPath];
        soundCheck.running = true;
    }
    Process {
        id: soundCheck
        onExited: code => store.soundOk = code === 0
    }

    // Diálogo de GTK para elegir un archivo de audio
    function pickSound() {
        if (picker.running)
            return;
        const cur = set.sound !== "system" && set.sound !== "" ? set.sound.substring(0, set.sound.lastIndexOf("/")) : "";
        picker.command = ["python3", Quickshell.shellPath("scripts/pick.py"), "file", cur, "Elegir sonido", "*.oga", "*.ogg", "*.wav", "*.flac", "*.mp3"];
        picker.running = true;
    }
    Process {
        id: picker
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p !== "")
                    store.setSound(p);
            }
        }
    }

    // ── Cronómetro ──
    function swElapsed() {
        const s = stopwatch;
        return s.state === "running" ? s.acc + Math.max(0, now - s.since) : s.acc;
    }

    function swSet(fields) {
        stopwatch = Object.assign({}, stopwatch, fields);
        save();
    }

    function swToggle() {
        now = Date.now();
        const s = stopwatch;
        if (s.state === "running")
            swSet({
                state: "paused",
                acc: s.acc + Math.max(0, Date.now() - s.since)
            });
        else
            swSet({
                state: "running",
                since: Date.now()
            });
    }

    function swLap() {
        if (stopwatch.state === "idle")
            return;
        now = Date.now();
        swSet({
            laps: stopwatch.laps.concat([Math.round(swElapsed())])
        });
    }

    function swReset() {
        swSet({
            state: "idle",
            since: 0,
            acc: 0,
            laps: []
        });
    }

    // Las vueltas, de la última a la primera: { n, split, total, best, worst }
    readonly property var lapRows: {
        const laps = stopwatch.laps;
        const rows = laps.map((total, i) => ({
                    n: i + 1,
                    split: total - (i > 0 ? laps[i - 1] : 0),
                    total: total,
                    best: false,
                    worst: false
                }));
        if (rows.length >= 2) {
            const splits = rows.map(r => r.split);
            const lo = Math.min.apply(null, splits);
            const hi = Math.max.apply(null, splits);
            rows.forEach(r => {
                r.best = r.split === lo;
                r.worst = r.split === hi && hi !== lo;
            });
        }
        return rows.reverse();
    }

    // Texto para pegar: "1  5:47.04  5:47.04"
    function lapsText() {
        return lapRows.slice().reverse().map(r => r.n + "\t" + Duration.format(r.split, true) + "\t" + Duration.format(r.total, true)).join("\n");
    }

    function copyLaps() {
        if (lapRows.length === 0)
            return;
        Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy', "_", lapsText()]);
    }

    // ── Guardar y cargar ──
    function save() {
        if (ready)
            saveTimer.restart();
    }

    function flush() {
        saveTimer.stop();
        if (!ready)
            return;
        selfWrite.restart();
        file.setText(JSON.stringify({
            version: version,
            timers: timers,
            stopwatch: stopwatch,
            recents: recents
        }, null, 2));
    }

    Timer {
        id: saveTimer
        interval: store.cfg.saveDelay
        onTriggered: store.flush()
    }

    Timer {
        id: selfWrite
        interval: 500
    }

    function normTimer(t) {
        if (!t || typeof t !== "object" || !(t.total > 0))
            return null;
        const state = t.state === "paused" ? "paused" : "running";
        return {
            id: typeof t.id === "string" && t.id !== "" ? t.id : makeId(),
            name: typeof t.name === "string" ? t.name : "",
            total: Math.round(t.total),
            // Lo que sonaba y nadie atendió vuelve a correr ya vencido: avisa de nuevo al arrancar
            state: state,
            endsAt: Number(t.endsAt) || 0,
            left: Math.max(0, Number(t.left) || 0),
            created: Number(t.created) || Date.now(),
            pomo: t.pomo ?? null
        };
    }

    function normStopwatch(s) {
        const ok = s && typeof s === "object";
        const state = ok && (s.state === "running" || s.state === "paused") ? s.state : "idle";
        return {
            state: state,
            since: state === "running" ? Number(s.since) || Date.now() : 0,
            acc: state === "idle" ? 0 : Math.max(0, Number(s.acc) || 0),
            laps: state !== "idle" && Array.isArray(s.laps) ? s.laps.filter(n => typeof n === "number") : []
        };
    }

    function load(text) {
        let raw = {};
        if (text.trim() !== "") {
            try {
                raw = JSON.parse(text);
            } catch (e) {
                // Roto: se guarda una copia aparte y se sigue con lo vacío
                Quickshell.execDetached(["cp", "-f", cfg.file, cfg.file + ".bak"]);
                Quickshell.execDetached(["notify-send", "-a", "Temporizador", "-i", "dialog-warning", "timers.json tiene un error", "Se guardó una copia en timers.json.bak y se empieza de cero"]);
                raw = {};
            }
        }
        timers = (Array.isArray(raw.timers) ? raw.timers : []).map(normTimer).filter(t => t !== null).slice(0, cfg.maxTimers);
        stopwatch = normStopwatch(raw.stopwatch);
        recents = (Array.isArray(raw.recents) ? raw.recents : []).filter(r => r && r.ms > 0).map(r => ({
                    ms: Math.round(r.ms),
                    name: typeof r.name === "string" ? r.name : ""
                })).slice(0, cfg.recents);
        ready = true;
        // Lo vencido con la shell cerrada o la laptop suspendida avisa ya
        tick();
    }

    // La carpeta debe existir antes de leer o escribir el archivo
    Process {
        running: true
        command: ["mkdir", "-p", store.cfg.file.substring(0, store.cfg.file.lastIndexOf("/"))]
        onExited: file.path = store.cfg.file
    }

    FileView {
        id: file
        atomicWrites: true
        printErrors: false
        onLoaded: store.load(text())
        // Sin archivo: arranca vacío y se crea al primer cambio
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                store.load("");
        }
    }

    Component.onCompleted: checkSound()
    // Lo que esté pendiente se guarda al cerrar la shell
    Component.onDestruction: flush()

    // ── IPC ──
    // qs ipc call stixshell@timer start "10m té" | pause <id|all> | stop <id|all> | list | stopwatch toggle|lap|reset | open timer|stopwatch
    IpcHandler {
        target: "stixshell@timer"

        function start(text: string): string {
            if (!store.ready)
                return "error: timers.json aún no se leyó";
            const id = store.addFromText(text);
            return id !== "" ? id : "error: no entiendo «" + text + "» (ejemplos: 10m té, 1h30, 5:00)";
        }
        function pause(id: string): string {
            if (id === "all") {
                store.pauseAll();
                return "ok";
            }
            return store.toggle(id) ? "ok" : "error: no existe " + id;
        }
        function stop(id: string): string {
            if (id === "all") {
                store.stopAll();
                return "ok";
            }
            return store.remove(id) ? "ok" : "error: no existe " + id;
        }
        function list(): string {
            const rows = store.timers.map(t => t.id + "  " + t.state + "  " + Duration.format(Math.ceil(store.left(t) / 1000) * 1000) + "  " + store.labelFor(t));
            if (store.swActive)
                rows.push("cronómetro  " + store.stopwatch.state + "  " + Duration.format(store.swElapsed(), true) + "  " + store.stopwatch.laps.length + " vueltas");
            return rows.join("\n");
        }
        function stopwatch(action: string): string {
            if (action === "toggle")
                store.swToggle();
            else if (action === "lap")
                store.swLap();
            else if (action === "reset")
                store.swReset();
            else
                return "error: usa toggle, lap o reset";
            return Duration.format(store.swElapsed(), true);
        }
        function open(tab: string): void {
            store.openRequested(tab === "stopwatch" ? "stopwatch" : "timer");
        }
    }
}
