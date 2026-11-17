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
import "./services/session/" as SS
import "./services/brightness/" as BR
import "./services/lock/" as LK
import "./services/idle/" as ID
import "./services/power/" as PW
import "./services/settings/" as SE
import "./services/media/" as MD
import "./components/lock/" as LC
import "./components/widgets/region/" as RG
import "./components/widgets/screenshot/" as SC
import "./services/screenshot/" as SH
import "./services/theme/" as TH
import "./services/calendar/" as CAL
import "./services/tasks/" as TK

ShellRoot {
    // Referencia para instanciar el singleton (toma el inhibidor del botón de encendido)
    readonly property var sessionActions: SS.SessionStore.actions
    // Instancia el store de brillo desde el inicio (su IPC debe existir para las teclas)
    readonly property var brightnessValue: BR.BrightnessStore.value
    // Instancian el bloqueo (IPC stixshell@lock) y la inactividad
    readonly property var lockLocked: LK.LockStore.locked
    readonly property var idleBattery: ID.IdleStore.onBattery
    // Instancian los avisos de batería baja y los ajustes (settings.json)
    readonly property var batteryPercent: PW.BatteryStore.percent
    // Instancia el perfil de energía automático (cambia al enchufar o desenchufar)
    readonly property var powerProfile: PW.ProfileStore.profile
    readonly property var settingsData: SE.SettingsStore.idle
    // Instancia el reproductor (IPC stixshell@media para las teclas multimedia)
    readonly property var mediaPlayer: MD.MediaStore.player
    // Instancia el capturador (IPC stixshell@screenshot para Impr Pant)
    readonly property var screenshotPhase: SH.ScreenshotStore.phase
    // Instancia los colores del wallpaper (regenera al cambiar de wallpaper; IPC stixshell@theme)
    readonly property var themeBusy: TH.ThemeStore.busy
    // Instancia el calendario (se actualiza al iniciar, al despertar y según calendar.refresh)
    readonly property var calendarUpdated: CAL.CalendarStore.updated
    // Instancia las tareas (lee tasks.json; IPC stixshell@tasks)
    readonly property var tasksReady: TK.TaskStore.ready

    // ── Pantalla de bloqueo ──
    LC.LockScreen {}

    // ── Selector de región (grabador y VPN) ──
    RG.RegionSelector {}

    // ── Capturador de pantalla (Impr Pant, Super+Shift+S o la casilla Captura) ──
    SC.ScreenshotOverlay {}

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
            onActivated: P.PanelStore.escapePressed()
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
                item: clockPill
            }
            Region {
                item: mediaMask
            }
            Region {
                item: recMask
            }
            Region {
                item: shotMask
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
            I.Workspaces {
                id: workspacesPill
            }
            I.ActiveWindow {
                workspacesOpen: workspacesPill.expanded
            }
            I.Zoom {}
        }
        // ══ CENTRO: el reloj y, a su izquierda, la pill de música ══
        // Solo uno tiene el foco: con la música expandida, pasa al centro y el reloj (ya círculo) a su derecha.
        // `blend` (0 = reloj al centro, 1 = música al centro) se anima, y las posiciones se mezclan entre
        // las dos disposiciones, así el movimiento es continuo aunque los anchos también estén cambiando.
        Item {
            id: centerPill
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: App.Config.bar.exclusiveZone

            readonly property real gap: App.Config.bar.spacing
            property real blend: mediaPill.expanded ? 1 : 0
            Behavior on blend {
                NumberAnimation {
                    duration: App.Config.anim.pill
                    easing.type: Easing.OutCubic
                }
            }

            // Reloj al centro / música a su izquierda
            readonly property real clockA: (width - clockPill.width) / 2
            readonly property real mediaA: clockA - gap - mediaPill.width
            // Música al centro / reloj a su derecha
            readonly property real mediaB: (width - mediaPill.width) / 2
            readonly property real clockB: mediaB + mediaPill.width + gap

            I.Media {
                id: mediaPill
                x: centerPill.mediaA + (centerPill.mediaB - centerPill.mediaA) * centerPill.blend
            }
            IC.IslandCenter {
                id: clockPill
                compact: mediaPill.expanded
                x: centerPill.clockA + (centerPill.clockB - centerPill.clockA) * centerPill.blend
            }
            // El contador de la grabación, siempre pegado a la derecha del reloj
            I.Recorder {
                id: recPill
                x: clockPill.x + clockPill.width + centerPill.gap
            }
            // La cuenta regresiva del capturador, tras el contador de la grabación (si lo hay)
            I.Screenshot {
                id: shotPill
                x: recPill.x + (recPill.visible ? recPill.width + centerPill.gap : 0)
            }
        }
        // La máscara de la pill de música: sin ancho si no se ve (no captura clics vacíos)
        Item {
            id: mediaMask
            x: mediaPill.x
            y: mediaPill.y
            width: mediaPill.visible ? mediaPill.width : 0
            height: mediaPill.visible ? mediaPill.height : 0
        }
        // La máscara del contador de grabación
        Item {
            id: recMask
            x: recPill.x
            y: recPill.y
            width: recPill.visible ? recPill.width : 0
            height: recPill.visible ? recPill.height : 0
        }
        // La máscara de la cuenta regresiva del capturador
        Item {
            id: shotMask
            x: shotPill.x
            y: shotPill.y
            width: shotPill.visible ? shotPill.width : 0
            height: shotPill.visible ? shotPill.height : 0
        }
        Row {
            id: rightPill
            anchors.right: parent.right
            anchors.rightMargin: App.Config.bar.marginRight

            spacing: App.Config.bar.spacing

            I.Tray {}

            I.Network {}

            I.Bluetooth {}

            I.Battery {}

            I.Notifications {}
        }
    }
}
