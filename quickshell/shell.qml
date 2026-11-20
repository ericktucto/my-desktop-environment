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
import "./services/display/" as DP
import "./services/sound/" as SND
import "./components/settings/" as PR
import "./services/media/" as MD
import "./components/lock/" as LC
import "./components/widgets/region/" as RG
import "./components/widgets/screenshot/" as SC
import "./services/screenshot/" as SH
import "./services/theme/" as TH
import "./services/calendar/" as CAL
import "./services/tasks/" as TK

ShellRoot {
    id: root
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
    // Instancia las pantallas (IPC stixshell@display y perfiles al conectar un monitor)
    // Instancia los sonidos del sistema (escucha los eventos y su IPC stixshell@sound)
    readonly property var soundsOn: SND.SoundStore.ready
    readonly property var displayCount: DP.DisplayStore.monitors.length

    // Preferencias del sistema (ventana propia; Super+, o stixshell@settings)
    PR.SettingsWindow {}

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
                item: timerMask
            }
            Region {
                item: rightPill
            }
        }

        // ══ BARRA: left | center | right ══
        L.Bar {
            id: barRow
        }

        // ══ PILLS DE LA IZQUIERDA: en el orden de Preferencias → Barra e isla; crecen hacia abajo ══
        Row {
            id: leftPill
            anchors.left: parent.left
            anchors.leftMargin: App.Config.bar.marginLeft
            spacing: App.Config.bar.spacing
            Repeater {
                model: leftKey.split(",")
                Loader {
                    required property string modelData
                    visible: item?.inBar ?? true
                    sourceComponent: modelData === "workspaces" ? cWorkspaces : (modelData === "activeWindow" ? cActiveWindow : cZoom)
                }
            }
        }
        // ══ CENTRO: el reloj, a su izquierda la pill de música y a su derecha el temporizador ══
        // Solo uno tiene el foco: con la música expandida, pasa al centro y el reloj (ya círculo) a su derecha;
        // con el temporizador expandido, pasa al centro y el reloj (círculo) a su izquierda, y la música más allá.
        // `blend` (0 = reloj al centro, 1 = música al centro) y `blendT` (1 = temporizador al centro) se animan,
        // y las posiciones se mezclan entre las disposiciones, así el movimiento es continuo aunque los anchos
        // también estén cambiando. Nunca valen 1 a la vez: solo hay un panel abierto.
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

            property real blendT: timerPill.expanded ? 1 : 0
            Behavior on blendT {
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
            // Temporizador al centro / reloj a su izquierda / música a la izquierda del reloj
            readonly property real timerC: (width - timerPill.width) / 2
            readonly property real clockC: timerC - gap - clockPill.width
            readonly property real mediaC: clockC - gap - mediaPill.width

            I.Media {
                id: mediaPill
                x: centerPill.mediaA + (centerPill.mediaB - centerPill.mediaA) * centerPill.blend + (centerPill.mediaC - centerPill.mediaA) * centerPill.blendT
            }
            IC.IslandCenter {
                id: clockPill
                compact: mediaPill.expanded || timerPill.expanded
                x: centerPill.clockA + (centerPill.clockB - centerPill.clockA) * centerPill.blend + (centerPill.clockC - centerPill.clockA) * centerPill.blendT
            }
            // El contador de la grabación, pegado a la derecha del reloj (del temporizador, si está expandido)
            I.Recorder {
                id: recPill
                readonly property real afterClock: clockPill.x + clockPill.width + centerPill.gap
                readonly property real afterTimer: centerPill.timerC + timerPill.width + centerPill.gap
                x: afterClock + (afterTimer - afterClock) * centerPill.blendT
            }
            // La cuenta regresiva del capturador, tras el contador de la grabación (si lo hay)
            I.Screenshot {
                id: shotPill
                x: recPill.x + (recPill.visible ? recPill.width + centerPill.gap : 0)
            }
            // Temporizador y cronómetro, tras lo anterior (si lo hay); expandido, al centro
            I.TimerPill {
                id: timerPill
                readonly property real normalX: shotPill.x + (shotPill.visible ? shotPill.width + centerPill.gap : 0)
                x: normalX + (centerPill.timerC - normalX) * centerPill.blendT
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
        // La máscara del temporizador y el cronómetro
        Item {
            id: timerMask
            x: timerPill.x
            y: timerPill.y
            width: timerPill.visible ? timerPill.width : 0
            height: timerPill.visible ? timerPill.height : 0
        }
        Row {
            id: rightPill
            anchors.right: parent.right
            anchors.rightMargin: App.Config.bar.marginRight

            spacing: App.Config.bar.spacing

            Repeater {
                model: rightKey.split(",")
                Loader {
                    required property string modelData
                    visible: item?.inBar ?? true
                    sourceComponent: {
                        switch (modelData) {
                        case "tray":
                            return cTray;
                        case "network":
                            return cNetwork;
                        case "bluetooth":
                            return cBluetooth;
                        case "battery":
                            return cBattery;
                        default:
                            return cNotifications;
                        }
                    }
                }
            }
        }
    }

    // ── Pills de la barra (el orden de cada lado sale de settings.json → bar) ──
    // `wsOpen`: la vista general de workspaces está abierta (la pill de la ventana activa se oculta)
    property bool wsOpen: false
    // El orden como texto: así las pills no se vuelven a crear mientras no cambie
    readonly property string leftKey: SE.SettingsStore.barOrder("left").join(",")
    readonly property string rightKey: SE.SettingsStore.barOrder("right").join(",")
    Component {
        id: cWorkspaces
        I.Workspaces {
            onExpandedChanged: root.wsOpen = expanded
        }
    }
    Component {
        id: cActiveWindow
        I.ActiveWindow {
            workspacesOpen: root.wsOpen
        }
    }
    Component {
        id: cZoom
        I.Zoom {}
    }
    Component {
        id: cTray
        I.Tray {}
    }
    Component {
        id: cNetwork
        I.Network {}
    }
    Component {
        id: cBluetooth
        I.Bluetooth {}
    }
    Component {
        id: cBattery
        I.Battery {}
    }
    Component {
        id: cNotifications
        I.Notifications {}
    }
}
