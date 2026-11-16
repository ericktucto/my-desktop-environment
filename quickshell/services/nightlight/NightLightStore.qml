pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../osd/" as O
import "../settings/" as ST
import "../../" as App

// Luz nocturna con hyprsunset (proceso hijo de la shell: muere con ella y la pantalla vuelve a lo normal).
// Modos: "sun" (del atardecer al amanecer, con la ubicación de la zona horaria), "custom" (horas fijas) y
// "always". La shell calcula el horario y la transición gradual y le manda la temperatura a hyprsunset
// con `hyprctl hyprsunset` (hyprsunset no calcula el sol y wlsunset no funciona con el gamma de Hyprland 0.56).
// Los ajustes están en ST.SettingsStore.nightLight. IPC: qs ipc call stixshell@nightlight toggle|on|off|temperature|mode.
Singleton {
    id: store

    readonly property var cfg: App.Config.nightLight
    readonly property var st: ST.SettingsStore.nightLight

    // ── Disponibilidad y ubicación ──
    property bool available: false
    property bool ready: false          // el chequeo de arranque (y el pkill de uno suelto) ya terminó
    property bool startError: false     // hyprsunset no arranca
    property string zone: ""
    property real zoneLat: cfg.latitude
    property real zoneLon: cfg.longitude
    readonly property real lat: st.latitude !== "" && !isNaN(parseFloat(st.latitude)) ? parseFloat(st.latitude) : zoneLat
    readonly property real lon: st.longitude !== "" && !isNaN(parseFloat(st.longitude)) ? parseFloat(st.longitude) : zoneLon

    // ── Reloj: se actualiza cada minuto (vence la pausa, cambia el día, reintenta tras un error) ──
    property real nowMs: Date.now()
    property string dayKey: new Date().toDateString()

    Timer {
        interval: store.cfg.tick
        running: true
        repeat: true
        onTriggered: {
            store.nowMs = Date.now();
            store.dayKey = new Date().toDateString();
            store.zoneProc.running = true;
            if (store.startError) {
                store.startError = false;
                store.failures = 0;
                store.sync();
            }
        }
    }

    // ── Sol (algoritmo del Almanaque Astronómico, -0,833°) ──
    function dayOfYear(d) {
        return Math.round((Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()) - Date.UTC(d.getFullYear(), 0, 0)) / 86400000);
    }

    function sunEvent(date, rise) {
        const rad = Math.PI / 180;
        const lngHour = lon / 15;
        const n = dayOfYear(date);
        const t = n + ((rise ? 6 : 18) - lngHour) / 24;
        const m = 0.9856 * t - 3.289;
        let l = m + 1.916 * Math.sin(m * rad) + 0.020 * Math.sin(2 * m * rad) + 282.634;
        l = ((l % 360) + 360) % 360;
        let ra = Math.atan(0.91764 * Math.tan(l * rad)) / rad;
        ra = ((ra % 360) + 360) % 360;
        ra += Math.floor(l / 90) * 90 - Math.floor(ra / 90) * 90;
        ra /= 15;
        const sinDec = 0.39782 * Math.sin(l * rad);
        const cosDec = Math.cos(Math.asin(sinDec));
        const cosH = (Math.cos(87 * rad) - sinDec * Math.sin(lat * rad)) / (cosDec * Math.cos(lat * rad));
        if (cosH > 1 || cosH < -1)
            return null;
        const h = (rise ? 360 - Math.acos(cosH) / rad : Math.acos(cosH) / rad) / 15;
        const tt = h + ra - 0.06571 * t - 6.622;
        const ut = (((tt - lngHour) % 24) + 24) % 24;
        return Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) + ut * 3600000;
    }

    // Amaneceres y atardeceres de ayer, hoy y mañana, ordenados: { t, rise }
    readonly property var events: {
        dayKey;
        lat;
        lon;
        const out = [];
        const base = new Date();
        for (let off = -1; off <= 1; off++) {
            const d = new Date(base.getFullYear(), base.getMonth(), base.getDate() + off);
            for (const rise of [true, false]) {
                const t = store.sunEvent(d, rise);
                if (t !== null)
                    out.push({
                        t: t,
                        rise: rise
                    });
            }
        }
        out.sort((a, b) => a.t - b.t);
        return out;
    }

    // "HH:MM" → minutos del día
    function minutes(s) {
        const p = s.split(":");
        return parseInt(p[0]) * 60 + parseInt(p[1]);
    }

    function timeText(ms) {
        return Qt.formatTime(new Date(ms), "HH:mm");
    }

    // Próxima vez que el reloj marca "HH:MM", en ms
    function nextAt(hhmm) {
        const m = minutes(hhmm);
        const d = new Date(nowMs);
        d.setHours(Math.floor(m / 60), m % 60, 0, 0);
        if (d.getTime() <= nowMs)
            d.setDate(d.getDate() + 1);
        return d.getTime();
    }

    // ── Estado ──
    readonly property bool enabled: st.enabled
    readonly property bool paused: st.pausedUntil > nowMs
    readonly property bool previewing: previewTimer.running
    // De noche según el modo (con "always", siempre)
    readonly property bool activeNow: {
        if (st.mode === "always")
            return true;
        if (st.mode === "custom") {
            const m = minutes(Qt.formatTime(new Date(nowMs), "HH:mm"));
            const a = minutes(st.start);
            const b = minutes(st.end);
            return a > b ? (m >= a || m < b) : (m >= a && m < b);
        }
        let last = null;
        for (const e of events)
            if (e.t <= nowMs)
                last = e;
        return last ? !last.rise : false;
    }
    // Cuándo cambia entre día y noche (0 = nunca)
    readonly property real nextChange: {
        if (st.mode === "always")
            return 0;
        if (st.mode === "custom")
            return Math.min(nextAt(st.start), nextAt(st.end));
        const e = events.find(x => x.t > nowMs);
        return e ? e.t : 0;
    }

    readonly property string statusText: {
        if (!available)
            return "Instala hyprsunset";
        if (startError)
            return "No se pudo iniciar hyprsunset";
        if (!enabled)
            return "Desactivada";
        if (paused)
            return "Pausada hasta mañana";
        if (st.mode === "always" || nextChange === 0)
            return "Activada · " + st.temperature + " K";
        return (activeNow ? "Hasta las " : "Desde las ") + timeText(nextChange);
    }

    readonly property string osdText: {
        if (!available)
            return "Instala hyprsunset";
        if (!enabled)
            return "Luz nocturna apagada";
        if (paused)
            return "Luz nocturna pausada";
        return "Luz nocturna · " + st.temperature + " K";
    }

    // "Hoy de 18:12 a 05:43" (modo sun) o "De 19:00 a 07:00"
    readonly property string scheduleText: {
        if (st.mode === "always")
            return "Todo el día";
        if (st.mode === "custom")
            return "De " + st.start + " a " + st.end;
        const today = new Date(nowMs).toDateString();
        const set = events.find(e => !e.rise && new Date(e.t).toDateString() === today);
        if (!set)
            return "";
        const rise = events.find(e => e.rise && e.t > set.t);
        return "Hoy de " + timeText(set.t) + (rise ? " a " + timeText(rise.t) : "") + (zone !== "" ? " · " + zone : "");
    }

    function tempWord(k) {
        return k <= 3000 ? "Muy cálida" : (k <= 4000 ? "Cálida" : "Suave");
    }

    // ── hyprsunset ──
    // Corre mientras la luz nocturna está activada (o en una vista previa) y su temperatura se cambia en caliente
    // con `hyprctl hyprsunset temperature N` / `identity`: sin reiniciarlo ni parpadear.
    property int previewTemp: 0
    readonly property bool wantRun: available && ready && (enabled || previewing)

    // Cuándo empezó el último cambio entre día y noche: { t, toNight } (para la transición gradual)
    function prevAt(hhmm) {
        const m = minutes(hhmm);
        const d = new Date(nowMs);
        d.setHours(Math.floor(m / 60), m % 60, 0, 0);
        if (d.getTime() > nowMs)
            d.setDate(d.getDate() - 1);
        return d.getTime();
    }

    readonly property var lastEvent: {
        if (st.mode === "custom") {
            const a = prevAt(st.start);
            const b = prevAt(st.end);
            return a > b ? {
                t: a,
                toNight: true
            } : {
                t: b,
                toNight: false
            };
        }
        let last = null;
        for (const e of events)
            if (e.t <= nowMs)
                last = e;
        return last ? {
            t: last.t,
            toNight: !last.rise
        } : null;
    }

    // Temperatura que toca ahora, en K (0 = sin filtro). De día y de noche cambia de a poco en `transition` s.
    readonly property int targetK: {
        if (previewing)
            return previewTemp;
        if (!enabled || paused)
            return 0;
        const temp = st.temperature;
        if (st.mode === "always" || !lastEvent)
            return activeNow || st.mode === "always" ? temp : 0;
        const el = Math.max(0, Math.min(1, (nowMs - lastEvent.t) / (cfg.transition * 1000)));
        const k = lastEvent.toNight ? cfg.dayTemperature + (temp - cfg.dayTemperature) * el : temp + (cfg.dayTemperature - temp) * el;
        return k >= cfg.dayTemperature ? 0 : Math.round(k / 10) * 10;
    }

    // Se aplica cuando hyprsunset ya escucha (un instante después de arrancar)
    property bool listening: false
    property int appliedK: -1

    function applyTemp(force) {
        if (!listening)
            return;
        if (!force && appliedK === targetK)
            return;
        appliedK = targetK;
        Quickshell.execDetached(targetK > 0 ? ["hyprctl", "hyprsunset", "temperature", String(targetK)] : ["hyprctl", "hyprsunset", "identity"]);
    }

    onTargetKChanged: applyTemp(false)

    onWantRunChanged: sync()

    function sync() {
        if (startError)
            return;
        if (wantRun && !hyprsunset.running) {
            listening = false;
            appliedK = -1;
            hyprsunset.running = true;
        } else if (!wantRun && hyprsunset.running) {
            listening = false;
            Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
        }
    }

    // Reaplica la temperatura (tras apagar y encender la pantalla, por si el color se pierde)
    function reapply() {
        applyTemp(true);
    }

    // Si hyprsunset se cierra solo, se vuelve a lanzar; tras tres intentos seguidos se avisa en la vista
    property int failures: 0

    Process {
        id: hyprsunset
        command: ["hyprsunset", "-i"]
        onStarted: {
            stableTimer.restart();
            readyTimer.restart();
        }
        onExited: {
            readyTimer.stop();
            stableTimer.stop();
            store.listening = false;
            if (!store.wantRun)
                return;
            if (++store.failures >= 3)
                store.startError = true;
            else
                restartTimer.restart();
        }
    }
    Timer {
        id: readyTimer
        interval: 700
        onTriggered: {
            store.listening = true;
            store.applyTemp(true);
        }
    }
    // Dos segundos sin cerrarse: está sano
    Timer {
        id: stableTimer
        interval: 2000
        onTriggered: store.failures = 0
    }
    Timer {
        id: restartTimer
        interval: store.cfg.restartDelay
        onTriggered: store.sync()
    }

    // ── Acciones ──
    // El clic de la casilla: enciende, reanuda, pausa hasta el próximo amanecer o apaga
    function toggle() {
        if (!available)
            return;
        if (!enabled) {
            st.pausedUntil = 0;
            st.enabled = true;
        } else if (paused) {
            st.pausedUntil = 0;
        } else if (st.mode !== "always" && activeNow && nextChange > 0) {
            st.pausedUntil = nextChange;
        } else {
            st.enabled = false;
        }
    }

    function setEnabled(on) {
        st.pausedUntil = 0;
        st.enabled = on;
    }

    function resume() {
        st.pausedUntil = 0;
    }

    function setMode(m) {
        st.mode = m;
        st.pausedUntil = 0;
    }

    function setTemperature(k) {
        k = Math.max(cfg.tempMin, Math.min(cfg.tempMax, Math.round(k / cfg.tempStep) * cfg.tempStep));
        st.temperature = k;
        // Si no se vería el cambio (de día, apagada o pausada), se muestra unos segundos
        if (!(enabled && !paused && activeNow)) {
            previewTemp = k;
            previewTimer.restart();
        }
    }

    Timer {
        id: previewTimer
        interval: store.cfg.previewTime
    }

    // which = "start" | "end"; dir = ±1 (pasos de Config.nightLight.timeStep min). Nunca iguala a la otra.
    function stepTime(which, dir) {
        const other = minutes(which === "start" ? st.end : st.start);
        let m = minutes(st[which]);
        do {
            m = (((m + dir * cfg.timeStep) % 1440) + 1440) % 1440;
        } while (m === other);
        const s = String(Math.floor(m / 60)).padStart(2, "0") + ":" + String(m % 60).padStart(2, "0");
        st[which] = s;
    }

    // ── Arranque ──
    Process {
        running: true
        command: ["sh", "-c", "pkill -x hyprsunset; sleep 0.3; command -v hyprsunset >/dev/null && echo yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                store.available = text.trim() === "yes";
            }
        }
        onExited: store.ready = true
    }

    // Zona horaria → coordenadas (zone1970.tab: ±DDMM±DDDMM o ±DDMMSS±DDDMMSS)
    property Process zoneProc: Process {
        running: true
        command: ["sh", "-c", 'z=$(readlink /etc/localtime | sed "s|.*/zoneinfo/||"); echo "$z"; awk -v z="$z" \'$3==z{print $2; exit}\' /usr/share/zoneinfo/zone1970.tab']
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                store.zone = (lines[0] ?? "").trim();
                const m = /^([+-])(\d{2})(\d{2})(\d{2})?([+-])(\d{3})(\d{2})(\d{2})?$/.exec((lines[1] ?? "").trim());
                if (!m)
                    return;
                const dms = (sign, d, mi, s) => (sign === "-" ? -1 : 1) * (parseInt(d) + parseInt(mi) / 60 + (s ? parseInt(s) / 3600 : 0));
                store.zoneLat = dms(m[1], m[2], m[3], m[4]);
                store.zoneLon = dms(m[5], m[6], m[7], m[8]);
            }
        }
    }

    // ── IPC ──
    IpcHandler {
        target: "stixshell@nightlight"
        function toggle(): void {
            store.toggle();
            O.OsdStore.show("nightlight");
        }
        function on(): void {
            store.setEnabled(true);
            O.OsdStore.show("nightlight");
        }
        function off(): void {
            store.setEnabled(false);
            O.OsdStore.show("nightlight");
        }
        function temperature(k: int): void {
            store.setTemperature(k);
        }
        function mode(m: string): void {
            if (m === "sun" || m === "custom" || m === "always")
                store.setMode(m);
        }
    }
}
