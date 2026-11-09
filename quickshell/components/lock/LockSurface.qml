import QtQuick
import QtQuick.Effects
import Quickshell
import "../indicators/" as I
import "../../services/lock/" as L
import "../../" as App

// Contenido de la pantalla de bloqueo: wallpaper difuminado, reloj, usuario, contraseña,
// batería y botones de energía.
Item {
    id: root
    anchors.fill: parent

    readonly property var cfg: App.Config.lock

    readonly property var days: ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"]
    readonly property var months: ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"]

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
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
            blur: root.cfg.blur
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
        opacity: root.cfg.dim
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
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "hh:mm AP")
            color: App.Theme.white
            font.family: App.Config.fonts.mono
            font.pixelSize: root.cfg.clockSize
            font.weight: Font.Medium
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                const d = clock.date;
                const day = root.days[d.getDay()];
                return day.charAt(0).toUpperCase() + day.slice(1) + ", " + d.getDate() + " de " + root.months[d.getMonth()];
            }
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: root.cfg.dateSize
        }

        Item {
            width: 1
            height: 32
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

    // ── Botones de energía (abajo) ──
    PowerButtons {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.cfg.margin * 2
    }
}
