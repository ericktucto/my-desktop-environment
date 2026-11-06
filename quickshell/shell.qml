import QtQuick
import Quickshell
import Quickshell.Wayland
import "./" as App
import "./components/layouts/" as L
import "./components/widgets/" as W
import "./components/widgets/notifylist/" as N
import "./components/indicators/" as I
import "./components/pills/islandcenter/" as IC
import "./services/panels/" as P

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
        color: App.Theme.black

        W.WallpaperTransition {}
    }

    // ── Popups de notificaciones ──
    N.NotifyPopups {
        suppressed: P.PanelStore.anyExpanded
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
        exclusiveZone: App.Config.bar.exclusiveZone
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: P.PanelStore.anyExpanded ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Esc cierra cualquier panel abierto
        Shortcut {
            sequence: "Escape"
            enabled: P.PanelStore.anyExpanded
            onActivated: P.PanelStore.closeAll()
        }

        MouseArea {
            id: clickOutsideCatcher
            anchors.fill: parent
            visible: P.PanelStore.anyExpanded
            z: -1

            onClicked: P.PanelStore.closeAll()
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
            anchors.leftMargin: App.Config.bar.marginLeft
            spacing: App.Config.bar.spacing
            I.Workspaces {}
            I.Zoom {}
        }
        Row {
            id: centerPill
            anchors.horizontalCenter: parent.horizontalCenter
            IC.IslandCenter {}
        }
        Row {
            id: rightPill
            anchors.right: parent.right
            anchors.rightMargin: App.Config.bar.marginRight

            spacing: App.Config.bar.spacing

            I.Tray {}

            I.Audio {}

            I.Battery {}

            I.Notifications {}
        }
    }
}
