pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../" as App

// Lectura de workspaces y dispatchers de Hyprland (sintaxis Lua) para la pill
// de workspaces y su vista general.
Singleton {
    id: store

    readonly property int count: App.Config.workspaces.count
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
    readonly property int overviewHeight: cardHeight + 2 * App.Config.pill.padding

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
        const n = Math.max(1, Math.min(count, currentId + delta));
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
