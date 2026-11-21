pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../sound/" as SND
import "../settings/" as ST
import "../../" as App

// Historial de notificaciones.
// Cada notificación se copia a un objeto JS plano ("entrada") porque el objeto
// Notification de Quickshell se destruye cuando la app lo cierra. Las entradas
// solo se borran cuando el usuario lo pide, y se guardan en disco.
Singleton {
    id: store

    // Entradas, la más nueva primero:
    // { key, id, appName, appIcon, desktopEntry, summary, body, image,
    //   urgency, expireTimeout, time, read, actions: [{identifier, text}], alive }
    property var history: []
    // Keys con popup visible, la más nueva primero (no se guarda)
    property var popups: []
    property bool dnd: false
    // Se actualiza cada minuto para refrescar los "hace 5 min"
    property double now: Date.now()

    readonly property int unreadCount: history.filter(e => !e.read).length

    // No leídas de las últimas Config.lock.notifyMaxAge s, por app (para la pantalla de bloqueo):
    // { id, keys, latest, count, critical }, las críticas primero y luego la más nueva
    readonly property var unreadGroups: {
        const limit = now - App.Config.lock.notifyMaxAge * 1000;
        const groups = {};
        for (const e of history) {
            if (e.read || e.time < limit)
                continue;
            const id = e.desktopEntry || e.appName || "?";
            const g = groups[id] ?? (groups[id] = {
                id: id,
                keys: [],
                latest: e,
                count: 0,
                critical: false
            });
            g.keys.push(e.key);
            g.count++;
            if (e.time > g.latest.time)
                g.latest = e;
            if (e.urgency === NotificationUrgency.Critical)
                g.critical = true;
        }
        return Object.values(groups).sort((a, b) => (b.critical - a.critical) || (b.latest.time - a.latest.time));
    }

    // key -> Notification vivo (solo en memoria)
    property var liveMap: ({})
    property int seq: 0
    property bool loaded: false
    property var pendingRefresh: ({})

    // ── API pública ──

    function entry(key) {
        return history.find(e => e.key === key);
    }

    function remove(key) {
        const n = liveMap[key];
        delete liveMap[key];
        history = history.filter(e => e.key !== key);
        popups = popups.filter(k => k !== key);
        if (n)
            n.dismiss();
        save();
    }

    function clearAll() {
        const live = liveMap;
        liveMap = ({});
        history = [];
        popups = [];
        for (const k in live)
            live[k].dismiss();
        save();
    }

    function hidePopup(key) {
        popups = popups.filter(k => k !== key);
    }

    // Marca como leídas las entradas con esas keys (siguen en el historial)
    function markRead(keys) {
        const set = new Set(keys);
        history = history.map(e => set.has(e.key) && !e.read ? Object.assign({}, e, {
                read: true
            }) : e);
        save();
    }

    function markAllRead() {
        if (history.every(e => e.read))
            return;
        history = history.map(e => e.read ? e : Object.assign({}, e, {
                read: true
            }));
        save();
    }

    function activate(key) {
        const n = liveMap[key];
        if (n) {
            const a = n.actions.find(x => x.identifier === "default");
            if (a)
                a.invoke();
        }
        patch(key, {
            read: true
        });
        hidePopup(key);
        save();
    }

    function invokeAction(key, identifier) {
        const n = liveMap[key];
        const a = n ? n.actions.find(x => x.identifier === identifier) : null;
        if (a)
            a.invoke();
        patch(key, {
            read: true
        });
        hidePopup(key);
        save();
    }

    function isMuted(app) {
        return !!app && (ST.SettingsStore.notifications.muted ?? []).indexOf(app) >= 0;
    }

    function setMuted(app, on) {
        const list = (ST.SettingsStore.notifications.muted ?? []).filter(a => a !== app);
        if (on)
            list.push(app);
        ST.SettingsStore.notifications.muted = list;
        if (on) {
            // Lo que ya había sin leer de esa app deja de contar
            history = history.map(e => e.appName === app && !e.read ? Object.assign({}, e, {
                    read: true
                }) : e);
            popups = popups.filter(k => entry(k)?.appName !== app);
            save();
        }
    }

    // Todas las apps que han notificado (y las silenciadas aunque ya no estén en el historial), por nombre
    readonly property var appNames: {
        const set = new Set(ST.SettingsStore.notifications.muted ?? []);
        for (const app of Object.keys(ST.SettingsStore.sounds.apps ?? {}))
            set.add(app);
        for (const e of history)
            if (e.appName)
                set.add(e.appName);
        return Array.from(set).sort((a, b) => a.localeCompare(b));
    }

    // ── No molestar programado ──
    // Al llegar la hora de inicio se activa No molestar y a la de fin se desactiva (si lo activó el horario).
    // Un solo temporizador que salta al próximo límite: sin consultas periódicas.
    property bool dndBySchedule: false

    function minutesOf(hhmm) {
        const m = /^(\d{1,2}):(\d{2})$/.exec(hhmm ?? "");
        return m ? Math.min(23, +m[1]) * 60 + Math.min(59, +m[2]) : -1;
    }

    // Minutos desde 00:00 de la hora actual
    function nowMinutes() {
        const d = new Date();
        return d.getHours() * 60 + d.getMinutes();
    }

    function inSchedule() {
        const c = ST.SettingsStore.notifications.dndSchedule;
        const a = minutesOf(c.from), b = minutesOf(c.to), n = nowMinutes();
        if (!c.enabled || a < 0 || b < 0 || a === b)
            return false;
        return a < b ? n >= a && n < b : n >= a || n < b;
    }

    // Pone No molestar según el horario y programa el próximo límite
    function applySchedule(boundary) {
        const c = ST.SettingsStore.notifications.dndSchedule;
        scheduleTimer.stop();
        if (!c.enabled || minutesOf(c.from) < 0 || minutesOf(c.to) < 0 || minutesOf(c.from) === minutesOf(c.to)) {
            if (dndBySchedule)
                setDnd(false);
            return;
        }
        const inside = inSchedule();
        if (inside && (boundary || !dnd)) {
            // Al entrar al horario; al arrancar dentro de él solo si no estaba ya activo a mano
            if (!dnd)
                setDnd(true, true);
        } else if (!inside && dndBySchedule) {
            setDnd(false);
        }
        // Próximo límite: el inicio o el fin que venga antes
        const n = nowMinutes();
        const d = new Date();
        const secs = d.getSeconds() + d.getMilliseconds() / 1000;
        let wait = 24 * 60;
        for (const t of [minutesOf(c.from), minutesOf(c.to)]) {
            let diff = t - n;
            if (diff <= 0)
                diff += 24 * 60;
            wait = Math.min(wait, diff);
        }
        scheduleTimer.interval = Math.max(1000, Math.round(wait * 60000 - secs * 1000));
        scheduleTimer.start();
    }

    Timer {
        id: scheduleTimer
        onTriggered: store.applySchedule(true)
    }

    // Al cargar o editar el horario cambian varios valores seguidos: se aplica una vez, cuando se asientan
    Timer {
        id: recheck
        interval: 250
        onTriggered: store.applySchedule(true)
    }

    Connections {
        target: ST.SettingsStore.notifications.dndSchedule
        function onEnabledChanged() {
            recheck.restart();
        }
        function onFromChanged() {
            recheck.restart();
        }
        function onToChanged() {
            recheck.restart();
        }
    }

    // `bySchedule`: lo activa el horario (solo entonces el horario lo apaga al llegar la hora de fin)
    function setDnd(on, bySchedule) {
        dnd = on;
        dndBySchedule = !!bySchedule && on;
        if (on)
            popups = popups.filter(k => {
                const e = entry(k);
                return e && e.urgency === NotificationUrgency.Critical;
            });
        save();
    }

    // Origen del ícono de una entrada: { kind: "photo" | "app" | "none", source, app }
    // `app` es siempre el ícono de la app (respaldo si la foto no carga)
    function iconFor(e) {
        if (!e)
            return {
                kind: "none",
                source: "",
                app: ""
            };

        const fromName = name => {
            if (!name)
                return "";
            if (name.startsWith("/"))
                return "file://" + name;
            if (name.startsWith("file://"))
                return name;
            return Quickshell.iconPath(name, true);
        };

        let app = fromName(e.appIcon);
        if (!app && e.desktopEntry) {
            const d = DesktopEntries.byId(e.desktopEntry);
            if (d)
                app = fromName(d.icon);
        }

        const img = e.image || "";
        let photo = "";
        if (img.startsWith("/"))
            photo = "file://" + img;
        else if (img.startsWith("file://"))
            photo = img;
        // Las imágenes incrustadas solo existen mientras la notificación vive
        else if (img.startsWith("image://") && e.alive)
            photo = img;

        if (photo)
            return {
                kind: "photo",
                source: photo,
                app: app
            };
        return {
            kind: app ? "app" : "none",
            source: app,
            app: app
        };
    }

    // Prepara el cuerpo para StyledText (que ignora \n y intenta cargar <img>)
    function formatBody(text) {
        return (text || "").replace(/<img[^>]*>/gi, "").trim().replace(/\n{3,}/g, "\n\n").replace(/\n/g, "<br>");
    }

    // Hora compacta: "ahora", "8m", "3h", "ayer", "05/11"
    function ago(time) {
        const diff = Math.max(0, store.now - time);
        const min = Math.floor(diff / 60000);
        if (min < 1)
            return "ahora";
        if (min < 60)
            return min + "m";
        const t = new Date(time);
        const n = new Date(store.now);
        const startToday = new Date(n.getFullYear(), n.getMonth(), n.getDate()).getTime();
        if (time >= startToday)
            return Math.floor(min / 60) + "h";
        if (time >= startToday - 86400000)
            return "ayer";
        const pad = v => (v < 10 ? "0" : "") + v;
        return pad(t.getDate()) + "/" + pad(t.getMonth() + 1);
    }

    // ── Interno ──

    function patch(key, fields) {
        history = history.map(e => e.key === key ? Object.assign({}, e, fields) : e);
    }

    function keyOf(n) {
        for (const k in liveMap)
            if (liveMap[k] === n)
                return k;
        return "";
    }

    function snapshot(n, key, prev) {
        return {
            key: key,
            id: n.id,
            appName: n.appName || "",
            appIcon: n.appIcon || "",
            desktopEntry: n.desktopEntry || "",
            summary: n.summary || "",
            body: n.body || "",
            image: n.image || "",
            urgency: n.urgency,
            expireTimeout: n.expireTimeout,
            time: prev ? prev.time : Date.now(),
            read: prev ? prev.read : false,
            actions: n.actions.map(a => ({
                        identifier: a.identifier,
                        text: a.text
                    })),
            alive: true
        };
    }

    function showPopup(key) {
        const e = entry(key);
        if (!e)
            return;
        if (dnd && e.urgency !== NotificationUrgency.Critical)
            return;
        // Apps silenciadas (Preferencias → Notificaciones): quedan en el historial, sin popup ni sonido
        if (isMuted(e.appName))
            return;
        // El sonido de «notificación nueva» (Preferencias → Sonidos)
        SND.SoundStore.playNotification(e.urgency === NotificationUrgency.Critical, e.appName ?? "");
        const list = popups.filter(k => k !== key);
        list.unshift(key);
        popups = list.slice(0, Math.max(1, ST.SettingsStore.notifications.maxPopups));
    }

    // Conecta un Notification vivo a una entrada
    function attach(n, key) {
        liveMap[key] = n;
        n.closed.connect(() => store.onClosed(key));
        const again = () => store.scheduleRefresh(key);
        n.summaryChanged.connect(again);
        n.bodyChanged.connect(again);
        n.imageChanged.connect(again);
        n.actionsChanged.connect(again);
        n.urgencyChanged.connect(again);
    }

    // La app (o el timeout del daemon) cerró la notificación: la entrada se queda
    function onClosed(key) {
        delete liveMap[key];
        if (entry(key))
            patch(key, {
                alive: false
            });
        hidePopup(key);
        save();
    }

    function scheduleRefresh(key) {
        pendingRefresh[key] = true;
        refreshTimer.restart();
    }

    // Una notificación existente cambió (reemplazo con notify-send -r, progreso…)
    function refresh(key) {
        const n = liveMap[key];
        const prev = entry(key);
        if (!n || !prev)
            return;
        const e = snapshot(n, key, prev);
        e.time = Date.now();
        e.read = isMuted(e.appName);
        history = [e].concat(history.filter(x => x.key !== key));
        showPopup(key);
        save();
    }

    function onNotification(n) {
        ensureLoaded();
        n.tracked = true;

        // Ya conocida (reemplazo reemitido): se trata como refresh
        const known = keyOf(n);
        if (known) {
            scheduleRefresh(known);
            return;
        }

        // Recarga de la config: el server reemite las vivas. Se reenganchan sin duplicar.
        if (n.lastGeneration) {
            const prev = history.find(e => e.id === n.id && !liveMap[e.key]);
            if (prev) {
                attach(n, prev.key);
                history = history.map(e => e.key === prev.key ? snapshot(n, prev.key, prev) : e);
                save();
                return;
            }
        }

        const key = Date.now() + "-" + n.id + "-" + (seq++);
        attach(n, key);
        const first = snapshot(n, key, null);
        // Una app silenciada llega ya leída: no cuenta en la pill ni en el bloqueo
        if (isMuted(first.appName))
            first.read = true;
        history = [first].concat(history);
        showPopup(key);
        save();
    }

    // ── Persistencia ──

    function ensureLoaded() {
        if (loaded)
            return;
        loaded = true;
        try {
            const raw = file.text();
            if (raw) {
                const d = JSON.parse(raw);
                if (Array.isArray(d.history))
                    history = d.history.map(e => Object.assign({}, e, {
                            alive: false
                        }));
                dnd = !!d.dnd;
                dndBySchedule = !!d.dndBySchedule && dnd;
            }
        } catch (err) {
            console.warn("NotificationStore: no se pudo leer el historial:", err);
        }
    }

    function save() {
        saveTimer.restart();
    }

    FileView {
        id: file
        path: Quickshell.statePath("notifications.json")
        blockLoading: true
        printErrors: false
    }

    Timer {
        id: saveTimer
        interval: 300
        onTriggered: {
            const data = {
                version: 1,
                dnd: store.dnd,
                dndBySchedule: store.dndBySchedule,
                history: store.history.map(e => {
                    const c = Object.assign({}, e);
                    delete c.alive;
                    return c;
                })
            };
            file.setText(JSON.stringify(data));
        }
    }

    Timer {
        id: refreshTimer
        interval: 30
        onTriggered: {
            const keys = Object.keys(store.pendingRefresh);
            store.pendingRefresh = ({});
            keys.forEach(k => store.refresh(k));
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: store.now = Date.now()
    }

    readonly property var server: NotificationServer {
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        actionIconsSupported: true

        onNotification: n => store.onNotification(n)
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", Quickshell.stateDir]);
        ensureLoaded();
        applySchedule(false);
    }
}
