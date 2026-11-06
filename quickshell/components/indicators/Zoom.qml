import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../base" as Base
import "../../" as App

Base.Island {
    id: root

    readonly property string appId: App.Config.zoom.appId
    readonly property string fallbackIcon: App.Config.zoom.fallbackIcon
    // Entrada .desktop exportada por el flatpak (la misma que usa el launcher)
    readonly property var entry: DesktopEntries.byId(appId)
    // Ícono de bandeja de Zoom. Al ser una propiedad (se evalúa al cargar) Quickshell
    // levanta el servicio de bandeja y Zoom puede registrar su ícono ahí.
    readonly property var trayItem: SystemTray.items.values.find(i => ((i.id ?? "") + (i.title ?? "")).toLowerCase().includes("zoom"))

    // Zoom cerrado queda vivo en segundo plano: el segundo `zoom` solo responde
    // "another zoom instance is running" y no muestra nada. Por eso, al hacer clic:
    // 1) si hay una ventana de Zoom, se enfoca; 2) si no, se activa su ícono de
    // bandeja (lo que la restaura); 3) si no, se reinicia/lanza Zoom.
    function openZoom() {
        const win = ToplevelManager.toplevels.values.find(t => (t.appId ?? "").toLowerCase().includes("zoom"));
        if (win) {
            win.activate();
            return;
        }
        if (trayItem) {
            trayItem.activate();
            return;
        }
        // Sin ventana ni bandeja: o no está corriendo, o quedó zombi en segundo plano.
        // `flatpak kill` es inocuo si no corre; luego se lanza una instancia limpia.
        Quickshell.execDetached(["sh", "-c", "flatpak kill " + appId + " 2>/dev/null; flatpak run " + appId]);
    }

    Image {
        source: Quickshell.iconPath(root.entry?.icon ?? root.appId, true) || root.fallbackIcon
        sourceSize: Qt.size(App.Config.pill.iconSize, App.Config.pill.iconSize)
        width: App.Config.pill.iconSize
        height: App.Config.pill.iconSize
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: mouse.containsMouse ? 1 : 0.85
        scale: mouse.pressed ? 0.9 : 1

        Behavior on scale { NumberAnimation { duration: App.Config.anim.hover; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: App.Config.anim.hover } }
    }

    Text {
        id: label
        text: "Zoom"
        height: App.Config.pill.iconSize
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: App.Config.fontSize.sm
        color: App.Theme.white
        opacity: mouse.containsMouse ? 1 : 0.85

        Behavior on opacity { NumberAnimation { duration: App.Config.anim.hover } }
    }

    // Island solo habilita su MouseArea si tiene body, así que usamos uno propio.
    // Los hijos van al Row de contenido de Island (default property), por eso
    // se reasigna el parent a la pill completa: anchors.fill dentro de un Row lo rompe.
    MouseArea {
        id: mouse
        parent: root
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openZoom()
    }
}
