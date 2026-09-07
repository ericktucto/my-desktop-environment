import QtQuick
import Quickshell
import Quickshell.Wayland
import "./components/layouts/" as L
import "./components/base/" as B
import "./components/indicators/" as I

PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 320   // altura máxima (pill expandido + margen)
    exclusiveZone: 40     // solo la barra reserva espacio
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: {
        if (clockPill.expanded) return WlrKeyboardFocus.OnDemand

        return WlrKeyboardFocus.None
    }

    // ══ MASK: solo barra + pill capturan clics ══
    mask: Region {
        Region { item: barRow }
        Region { item: leftPill }
        Region { item: centerPill }
        Region { item: rightPill }
    }

    // ══ BARRA: left | center | right ══
    L.Bar {
        id: barRow
    }

    // ══ PILL: en el left, crece hacia abajo ══
    Row {
        id: leftPill
        anchors.left: parent.left
        anchors.leftMargin: 12
        I.Workspaces {}
    }
    Row {
        id: centerPill
        anchors.horizontalCenter: parent.horizontalCenter
        I.Clock {
            id: clockPill
        }
    }
    Row {
        id: rightPill
        anchors.right: parent.right
        anchors.rightMargin: 12
        I.Battery {}
    }
}
