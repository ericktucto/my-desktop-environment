pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../workspaces/" as W
import "../screenshot/" as SS
import "../../" as App
import "WindowMenu.js" as WM

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

    // ── Menú de la pill: acciones sobre la ventana que estaba activa al abrirlo ──
    // La ventana se fija por su dirección al abrir (aunque el foco cambie mientras el menú está abierto)
    property string targetAddress: ""
    readonly property var targetWindow: targetAddress === "" ? null : (Hyprland.toplevels.values.find(t => t.address === targetAddress) ?? null)
    // Datos de Hyprland de esa ventana (flotante, fijada, workspace, pid…); se leen al abrir
    readonly property var info: targetWindow?.lastIpcObject ?? ({})
    readonly property string className: info.class ?? appId

    // Otras ventanas de la misma app (la fijada primero)
    readonly property var sameApp: {
        const cls = (className ?? "").toLowerCase();
        if (targetAddress === "" || cls === "")
            return [];
        const out = Hyprland.toplevels.values.filter(t => (t.lastIpcObject?.class ?? "").toLowerCase() === cls);
        return out.sort((a, b) => (b.address === targetAddress) - (a.address === targetAddress));
    }
    readonly property var desktopActions: entry?.actions ?? []
    readonly property var shortcuts: WM.shortcutsFor(appId, App.Config.activeWindow)

    // El otro monitor, si hay dos sin espejar (para «Mover al otro monitor»)
    readonly property var otherMonitor: {
        const mine = info.monitor;
        return Hyprland.monitors.values.find(m => m.id !== mine && (m.lastIpcObject?.mirrorOf ?? "none") === "none") ?? null;
    }

    // Fija la ventana activa y lee su estado
    function lock() {
        targetAddress = Hyprland.activeToplevel?.address ?? "";
        Hyprland.refreshToplevels();
        Hyprland.refreshMonitors();
    }

    function unlock() {
        targetAddress = "";
    }

    function run(cmd) {
        Hyprland.dispatch(cmd);
    }

    function moveTo(ws) {
        if (targetAddress !== "")
            run(WM.move(targetAddress, ws));
    }
    function toggleStash() {
        if (targetAddress !== "")
            run(WM.move(targetAddress, WM.stashTarget(info, W.WorkspaceStore.currentId)));
    }
    function toggleFloat() {
        if (targetAddress !== "")
            run(WM.toggleFloat(targetAddress));
    }
    function togglePin() {
        if (targetAddress !== "")
            run(WM.pin(targetAddress));
    }
    function center() {
        if (targetAddress !== "")
            run(WM.center(targetAddress));
    }
    function toggleMaximize() {
        if (targetAddress !== "")
            run(WM.maximize(targetAddress));
    }
    function toggleFullscreen() {
        if (targetAddress !== "")
            run(WM.fullscreen(targetAddress));
    }
    // El grupo actúa sobre la ventana enfocada: se enfoca la fijada antes
    function toggleGroup() {
        if (targetAddress === "")
            return;
        run(WM.focus(targetAddress));
        run(WM.groupToggle());
    }
    function moveToMonitor() {
        if (targetAddress !== "" && otherMonitor)
            run(WM.moveToMonitor(targetAddress, otherMonitor.name));
    }
    function close() {
        if (targetAddress !== "")
            run(WM.close(targetAddress));
    }
    function kill() {
        if (targetAddress !== "")
            run(WM.kill(targetAddress));
    }
    function sendShortcut(keys) {
        if (targetAddress !== "")
            run(WM.sendShortcut(targetAddress, keys));
    }
    function focusWindow(t) {
        run(WM.focus(t.address));
    }
    // Sin acciones en el .desktop: abre otra instancia de la app
    function newInstance() {
        entry?.execute();
    }
    function copyClass() {
        if (className !== "")
            Quickshell.execDetached(["wl-copy", "--", className]);
    }
    function capture() {
        SS.ScreenshotStore.start("window");
    }
}
