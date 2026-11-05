pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
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

    function setDnd(on) {
        dnd = on;
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
        const list = popups.filter(k => k !== key);
        list.unshift(key);
        popups = list.slice(0, App.Config.notifications.maxPopups);
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
        e.read = false;
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
        history = [snapshot(n, key, null)].concat(history);
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
    }
}
