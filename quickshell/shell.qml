import QtQuick
import Quickshell
import Quickshell.Wayland
import "./components/layouts/" as L
import "./components/widgets/" as W
import "./components/indicators/" as I

ShellRoot {

    // ── Wallpaper de fondo ──
    PanelWindow {
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        WlrLayershell.layer: WlrLayer.Background
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        W.WallpaperTransition {}
    }

    PanelWindow {
        id: bar

        anchors {
            top: true
            left: true
            right: true
        }

        // altura máxima (pill expandido + margen)
        implicitHeight: bar.screen ? bar.screen.height : 0
        // solo la barra reserva espacio
        exclusiveZone: 40
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: {
            if (clockPill.expanded)
                return WlrKeyboardFocus.Exclusive;

            return WlrKeyboardFocus.None;
        }

        MouseArea {
            id: clickOutsideCatcher
            anchors.fill: parent
            visible: clockPill.expanded
            z: -1

            onClicked: {
                if (clockPill.expanded)
                    clockPill.expanded = false;
            }
        }

        // ══ MASK: solo barra + pill capturan clics ══
        mask: Region {
            Region {
                item: barRow
            }
            Region {
                item: leftPill
            }
            Region {
                item: centerPill
            }
            Region {
                item: rightPill
            }
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
}
