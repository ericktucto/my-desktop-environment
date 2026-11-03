import QtQuick
import Quickshell
import "../base" as Base
import "../../" as App

Base.Island {
    id: root

    // margen lateral (12) x2 + icono (16) + separación (6) + texto
    collapsedWidth: 12 * 2 + 16 + 6 + label.implicitWidth

    readonly property string appId: "us.zoom.Zoom"
    readonly property string fallbackIcon: "file:///var/lib/flatpak/exports/share/icons/hicolor/64x64/apps/us.zoom.Zoom.png"
    // Entrada .desktop exportada por el flatpak (la misma que usa el launcher)
    readonly property var entry: DesktopEntries.byId(appId)

    Image {
        source: Quickshell.iconPath(root.entry?.icon ?? root.appId, true) || root.fallbackIcon
        sourceSize: Qt.size(16, 16)
        width: 16
        height: 16
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: mouse.containsMouse ? 1 : 0.85
        scale: mouse.pressed ? 0.9 : 1

        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Text {
        id: label
        text: "Zoom"
        leftPadding: 6
        height: 16
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 12
        color: App.Theme.white
        opacity: mouse.containsMouse ? 1 : 0.85

        Behavior on opacity { NumberAnimation { duration: 120 } }
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
        onClicked: {
            if (root.entry)
                root.entry.execute();
            else
                Quickshell.execDetached(["flatpak", "run", root.appId]);
        }
    }
}
