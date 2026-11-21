import QtQuick
import QtQuick.Effects
import Quickshell
import "../indicators/" as I
import "../../services/lock/" as L
import "../../services/settings/" as ST
import "../../services/settings/Clock.js" as Fmt
import "../../" as App

// Contenido de la pantalla de bloqueo: wallpaper difuminado, reloj, música, usuario, contraseña (con el aviso
// de Bloq Mayús y Bloq Num), notificaciones no leídas (solo en la pantalla de la laptop), batería y botones de energía.
Item {
    id: root
    anchors.fill: parent

    readonly property var cfg: App.Config.lock
    // Nombre de la pantalla (las notificaciones salen en la de la laptop)
    property string screenName: ""

    // Preferencias → Bloqueo y reloj
    readonly property var prefs: ST.SettingsStore.lock
    readonly property var clockPrefs: ST.SettingsStore.clock

    SystemClock {
        id: clock
        precision: root.clockPrefs.seconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    // ── Fondo: wallpaper difuminado y oscurecido, con las esquinas redondeadas de la shell ──
    Rectangle {
        anchors.fill: parent
        color: App.Theme.black
    }

    Image {
        id: wall
        anchors.fill: parent
        source: App.Wallpaper.current ? "file://" + App.Wallpaper.current : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.prefs.blur
            blurMax: root.cfg.blurMax
            maskEnabled: true
            maskThresholdMin: 0.5
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: wall.width
                    height: wall.height
                    radius: App.Config.wallpaper.radius
                    color: App.Theme.black
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: App.Config.wallpaper.radius
        color: "black"
        opacity: root.prefs.dim
    }

    // ── Batería (arriba a la derecha) ──
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: root.cfg.margin
        height: App.Config.pill.height
        width: battery.implicitWidth + 2 * App.Config.pill.paddingX
        radius: height / 2
        color: App.Theme.island

        I.BatteryText {
            id: battery
            anchors.centerIn: parent
        }
    }

    // ── Centro: reloj, fecha, usuario y contraseña ──
    Column {
        id: center
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Fmt.time(clock.date, root.clockPrefs.hour12, root.clockPrefs.seconds)
            color: App.Theme.white
            font.family: App.Config.fonts.mono
            font.pixelSize: root.cfg.clockSize
            font.weight: Font.Medium
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Fmt.date(clock.date, root.clockPrefs.dateFormat, true)
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: root.cfg.dateSize
        }

        LockMedia {
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item {
            width: 1
            height: 24
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: L.LockStore.userName
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: root.cfg.userSize
            font.weight: Font.Medium
        }

        PasswordField {
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // ── Notificaciones: debajo del campo; el reloj y el campo no se mueven ──
    LockNotifications {
        id: notifications
        visible: root.prefs.notifications && groups.length > 0 && L.LockStore.notifyScreen(root.screenName)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height / 2) + fieldBottom
        // Alto del reloj, la fecha, la música y el usuario por encima del centro varía: se mide el bloque
        readonly property real fieldBottom: center.height / 2 + 12
        availHeight: powerButtons.y - y - 16
    }

    // ── Botones de energía (abajo) ──
    PowerButtons {
        id: powerButtons
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.cfg.margin * 2
    }
}
