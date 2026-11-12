pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../workspaces/" as W

// Ventana enfocada: nombre de la app, título e ícono para la pill de la barra.
// Usa ToplevelManager (foreign-toplevel): conoce las ventanas desde que la shell arranca.
Singleton {
    id: store

    // DesktopEntries solo se llena mientras alguien lo usa
    readonly property var desktopApps: DesktopEntries.applications.values

    // La ventana enfocada (null en un workspace vacío). Los paneles de la shell no la vacían:
    // se comprobó con el launcher, el portapapeles y el centro de control abiertos.
    readonly property var shown: ToplevelManager.activeToplevel
    readonly property bool visible: shown !== null

    readonly property string appId: shown?.appId ?? ""
    // Leer desktopApps vuelve a evaluar esto cuando DesktopEntries termina de llenarse (al arrancar está vacío)
    readonly property var entry: desktopApps.length >= 0 && appId !== "" ? DesktopEntries.heuristicLookup(appId) : null

    // "us.zoom.Zoom" → "Zoom"; "kitty" → "Kitty"
    readonly property string name: {
        if (entry?.name)
            return entry.name;
        if (appId === "")
            return "Ventana";
        const last = appId.substring(appId.lastIndexOf(".") + 1);
        return last.charAt(0).toUpperCase() + last.slice(1);
    }

    // Sin el sufijo del navegador y sin repetir el nombre
    readonly property string title: {
        if (!shown)
            return "";
        let t = W.WorkspaceStore.titleOf(shown);
        if (appId === "" && t === "")
            return "";
        const n = name.toLowerCase();
        if (t.toLowerCase() === n || t.toLowerCase() === appId.toLowerCase())
            return "";
        const m = t.match(/^(.*?)\s[—–-]\s(.+)$/);
        if (m && m[2].toLowerCase() === n)
            t = m[1];
        return t;
    }

    readonly property string icon: desktopApps.length >= 0 ? W.WorkspaceStore.iconFor(appId) : ""

    function closeActive() {
        if (shown)
            shown.close();
    }
}
