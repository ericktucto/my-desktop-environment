import QtQuick
import Quickshell
import "../../indicators/" as IN
import "../../../services/audio/" as A
import "../../../services/notify/" as N
import "../../../services/brightness/" as B
import "../../../services/idle/" as I
import "../../../services/power/" as P
import "../../../services/settings/" as ST
import "../../../" as App

// Centro de control: casillas rápidas, brillo, salida y micrófono, y abajo apagar, batería y ajustes.
// Wi-Fi, Bluetooth, Luz nocturna y Captura son solo visuales por ahora ("Próximamente").
Column {
    id: root

    spacing: 14

    // El menú de sesión (botón de apagar) y cerrar la isla (tras abrir los ajustes)
    signal sessionRequested
    signal closeRequested

    // El estado de la luz del teclado y del daemon de energía no avisa: se vuelve a leer al abrir
    function refresh() {
        B.BrightnessStore.refresh();
        B.KbdLightStore.refresh();
        P.ProfileStore.refresh();
    }

    readonly property var saverProfile: P.ProfileStore.byKey("power-saver")

    function glyph(code) {
        return String.fromCodePoint(code);
    }

    // ── Casillas ──
    Grid {
        id: grid
        width: parent.width
        columns: 2
        spacing: App.Config.control.tileSpacing

        readonly property real tileWidth: (width - spacing) / 2

        ControlTile {
            width: grid.tileWidth
            glyph: root.glyph(0xf05a9)
            title: "Wi-Fi"
            subtitle: "Próximamente"
            detail: true
            ready: false
        }
        ControlTile {
            width: grid.tileWidth
            glyph: root.glyph(0xf00af)
            title: "Bluetooth"
            subtitle: "Próximamente"
            detail: true
            ready: false
        }
        ControlTile {
            width: grid.tileWidth
            icon: Qt.resolvedUrl("../../../assets/svg/" + (N.NotificationStore.dnd ? "notification-off" : "notification-on") + ".svg")
            title: "No molestar"
            subtitle: N.NotificationStore.dnd ? "Activado" : "Desactivado"
            checked: N.NotificationStore.dnd
            onClicked: N.NotificationStore.setDnd(!N.NotificationStore.dnd)
        }
        ControlTile {
            width: grid.tileWidth
            glyph: root.glyph(0xf0176)
            title: "Cafeína"
            subtitle: I.IdleStore.caffeine ? "Activada" : "Desactivada"
            checked: I.IdleStore.caffeine
            activeColor: App.Theme.amber
            onClicked: I.IdleStore.toggleCaffeine()
        }
        ControlTile {
            width: grid.tileWidth
            glyph: root.glyph(0xf0594)
            title: "Luz nocturna"
            subtitle: "Próximamente"
            ready: false
        }
        ControlTile {
            width: grid.tileWidth
            glyph: root.glyph(0xf030c)
            title: "Luz del teclado"
            subtitle: B.KbdLightStore.label
            checked: B.KbdLightStore.on
            ready: B.KbdLightStore.available
            onClicked: B.KbdLightStore.toggle()
        }
        ControlTile {
            width: grid.tileWidth
            glyph: root.glyph(0xf019e)
            title: "Captura"
            subtitle: "Próximamente"
            ready: false
        }
        ControlTile {
            width: grid.tileWidth
            glyph: root.glyph(root.saverProfile.glyph)
            title: "Ahorro"
            subtitle: !P.ProfileStore.available ? "No disponible" : (P.ProfileStore.saver ? "Activado" : "Desactivado")
            checked: P.ProfileStore.saver
            activeColor: root.saverProfile.color
            ready: P.ProfileStore.available
            onClicked: P.ProfileStore.toggleSaver()
        }
    }

    BrightnessSection {
        width: parent.width
        visible: B.BrightnessStore.available
    }

    Rectangle {
        width: parent.width
        height: 1
        color: App.Theme.islandEdge
    }

    AudioSection {
        width: parent.width
        title: "SALIDA"
        isSink: true
        node: A.AudioStore.sink
        devices: A.AudioStore.sinks
        onSelect: d => A.AudioStore.setDefaultSink(d)
    }

    Rectangle {
        width: parent.width
        height: 1
        color: App.Theme.islandEdge
    }

    AudioSection {
        width: parent.width
        title: "MICRÓFONO"
        isSink: false
        node: A.AudioStore.source
        devices: A.AudioStore.sources
        onSelect: d => A.AudioStore.setDefaultSource(d)
    }

    // ── Fila de abajo: apagar · batería · ajustes ──
    Item {
        width: parent.width
        height: App.Config.control.footerHeight

        FooterButton {
            id: powerButton
            glyph: root.glyph(0xf0425)
            onClicked: root.sessionRequested()
        }

        FooterButton {
            id: settingsButton
            anchors.right: parent.right
            glyph: root.glyph(0xf0493)
            onClicked: {
                // kitty con tu editor (EDITOR, o nvim) sobre settings.json; se aplica al guardar
                Quickshell.execDetached(["kitty", "sh", "-c", 'exec "${EDITOR:-nvim}" "$1"', "_", ST.SettingsStore.filePath]);
                root.closeRequested();
            }
        }

        // Pill de batería: abre el panel de batería
        Rectangle {
            anchors.left: powerButton.right
            anchors.leftMargin: 8
            anchors.right: settingsButton.left
            anchors.rightMargin: 8
            height: parent.height
            radius: height / 2
            color: batteryMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface

            Behavior on color {
                ColorAnimation {
                    duration: App.Config.anim.control
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: App.Config.pill.contentSpacing

                IN.BatteryText {
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "· " + P.BatteryStore.shortText
                    color: App.Theme.gray
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                }
            }

            MouseArea {
                id: batteryMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: P.BatteryStore.openPanel()
            }
        }
    }
}
