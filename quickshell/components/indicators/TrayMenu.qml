import QtQuick
import Quickshell
import "../../" as App

// Menú contextual de un ícono del tray, con el estilo de las pills.
PopupWindow {
    id: root

    // QsMenuHandle del SystemTrayItem
    property var menuSource
    // Item al que se ancla (el ícono)
    property Item anchorItem

    anchor.item: anchorItem
    // Debajo del ícono, alineado a su borde derecho y creciendo hacia la izquierda
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 8
    anchor.adjustment: PopupAdjustment.All

    // Un clic fuera cierra el menú
    grabFocus: true
    color: "transparent"

    implicitWidth: panel.width
    implicitHeight: panel.height

    Rectangle {
        id: panel

        readonly property int pad: App.Config.tray.menuPadding

        width: Math.max(App.Config.tray.menuMinWidth, list.implicitWidth + 2 * pad)
        height: list.implicitHeight + 2 * pad
        radius: App.Config.radius.md + pad
        color: App.Theme.island
        border.width: 1
        border.color: App.Theme.islandEdge

        // Absorbe clics en huecos del menú
        MouseArea {
            anchors.fill: parent
        }

        TrayMenuList {
            id: list
            x: panel.pad
            y: panel.pad
            width: panel.width - 2 * panel.pad
            source: root.menuSource
            onActivated: root.visible = false
        }
    }
}
