pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../settings/" as ST
import "../../" as App

// Lectura de workspaces y dispatchers de Hyprland (sintaxis Lua) para la pill
// de workspaces y su vista general.
Singleton {
    id: store

    // Cantidad de workspaces (Preferencias → Barra e isla): de 1 a 10
    readonly property int count: Math.max(1, Math.min(10, ST.SettingsStore.workspaces.count))
    // Los atajos Super+N de Hyprland leen la cantidad de este archivo al pulsar
    readonly property string countFile: Quickshell.env("HOME") + "/.cache/stixshell/workspaces"
    onCountChanged: writeCount()
    function writeCount() {
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\n" "$2" > "$1"', "_", countFile, String(count)]);
    }
    Component.onCompleted: writeCount()

    // Los que se muestran: de 1 a `count` y los de más arriba que tengan ventanas (para no esconderlas)
    readonly property var shown: {
        const ids = [];
        for (let i = 1; i <= count; i++)
            ids.push(i);
        for (const w of Hyprland.workspaces.values)
            if (w.id > count && w.id <= 10 && (w.toplevels?.values?.length ?? 0) > 0)
                ids.push(w.id);
        return ids.sort((a, b) => a - b);
    }
    // Un elemento por workspace mostrado: { id, active, occupied, extra, apps: [{ icon, name }] }
    // (el modelo de todos los estilos de la pill y del aviso al pasar el mouse)
    readonly property var items: shown.map(id => {
        const ts = windows(id);
        return {
            id: id,
            active: id === currentId,
            occupied: ts.length > 0,
            extra: id > count,
            apps: ts.map(t => ({
                        icon: appIcon(t),
                        name: titleOf(t) !== "" ? (t.wayland?.appId || t.lastIpcObject?.class || titleOf(t)) : ""
                    }))
        };
    })

    // Vista general: en dos filas con 7 o más workspaces, para que quepa en la pantalla
    readonly property int overviewColumns: count >= 7 ? Math.ceil(count / 2) : count
    readonly property int overviewRows: Math.ceil(count / overviewColumns)
    readonly property int overviewWidth: overviewColumns * App.Config.workspaces.cardWidth + (overviewColumns - 1) * App.Config.workspaces.cardSpacing + 2 * App.Config.pill.padding
    // Workspace normal activo (aunque el stash esté visible)
    readonly property int currentId: {
        const id = Hyprland.focusedMonitor?.activeWorkspace?.id;
        return id > 0 ? id : 1;
    }

    // Filas de la vista general: las del workspace con más ventanas (entre minRows y maxRows)
    readonly property int maxWindows: {
        let m = 0;
        for (let i = 1; i <= count; i++)
            m = Math.max(m, windows(i).length);
        return m;
    }
    readonly property int rows: Math.max(App.Config.workspaces.minRows, Math.min(App.Config.workspaces.maxRows, maxWindows))
    readonly property int cardHeight: 2 * App.Config.workspaces.cardPadding + App.Config.workspaces.headerHeight + rows * App.Config.workspaces.rowHeight + (rows - 1) * App.Config.workspaces.rowSpacing
    readonly property int overviewHeight: overviewRows * cardHeight + (overviewRows - 1) * App.Config.workspaces.cardSpacing + 2 * App.Config.pill.padding

    function workspace(id) {
        return Hyprland.workspaces.values.find(w => w.id === id);
    }

    function windows(id) {
        // toplevels puede no existir un instante mientras Hyprland destruye el workspace
        return workspace(id)?.toplevels?.values ?? [];
    }

    function focus(id) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })");
    }

    // Anterior (-1) o siguiente (+1); se detiene en 1 y en count
    function step(delta) {
        const i = shown.indexOf(currentId);
        const n = shown[Math.max(0, Math.min(shown.length - 1, (i < 0 ? 0 : i) + delta))];
        if (n !== currentId)
            focus(n);
    }

    function focusWindow(t) {
        Hyprland.dispatch("hl.dsp.focus({ window = \"address:0x" + t.address + "\" })");
    }

    // Mueve la ventana sin seguirla (igual que Super+Shift+N)
    function moveWindow(t, id) {
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + id + ", window = \"address:0x" + t.address + "\", follow = false })");
    }

    // Título de la ventana, sin el sufijo del navegador ("… — Mozilla Firefox")
    function titleOf(t) {
        const raw = t.title || t.lastIpcObject?.title || t.wayland?.appId || t.lastIpcObject?.class || "";
        return raw.replace(/\s[—–-]\s(Mozilla Firefox|Firefox|Zen Browser|Google Chrome|Chromium|Brave)$/, "") || raw;
    }

    function iconPath(name) {
        if (!name)
            return "";
        if (name.startsWith("/"))
            return "file://" + name;
        if (name.includes(":"))
            return name;
        return Quickshell.iconPath(name, true);
    }

    // Ícono de una app por su appId: el del .desktop y, si no hay, variantes del nombre
    // (minúsculas, última parte de "us.zoom.Zoom", guiones) antes del ícono genérico
    function iconFor(appId) {
        const generic = Quickshell.iconPath("application-x-executable", true);
        if (!appId)
            return generic;
        const entry = DesktopEntries.heuristicLookup(appId);
        const last = appId.substring(appId.lastIndexOf(".") + 1);
        const tries = [entry?.icon, appId, appId.toLowerCase(), last, last.toLowerCase(), appId.toLowerCase().replace(/[ _]/g, "-")];
        for (const n of tries) {
            const p = iconPath(n);
            if (p)
                return p;
        }
        return generic;
    }

    function appIcon(t) {
        return iconFor(t.wayland?.appId || t.lastIpcObject?.class || "");
    }
}
