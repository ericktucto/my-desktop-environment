import QtQuick
import "../../controls/" as C
import "../controlcenter/" as CC
import "../../../services/idle/" as I
import "../../../services/power/" as P
import "../../../services/settings/" as ST
import "../../../" as App

// Panel de energía (pill de batería): estado, cafeína, inactividad y avisos de batería baja.
Column {
    id: root

    property bool confirmingReset: false

    spacing: 14

    Timer {
        id: resetTimer
        interval: App.Config.notifications.clearConfirm
        onTriggered: root.confirmingReset = false
    }

    // ── Estado de la batería ──
    Item {
        width: parent.width
        height: status.implicitHeight

        Column {
            id: status
            width: parent.width
            spacing: 2

            Text {
                text: P.BatteryStore.percent + " %"
                color: App.Theme.white
                font.family: App.Config.fonts.mono
                font.pixelSize: 26
                font.weight: Font.Medium
            }
            Text {
                text: P.BatteryStore.stateText
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
            }
            Text {
                visible: text !== ""
                text: P.BatteryStore.detailText
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
        }

        // Modo conservación (IdeaPad): carga solo hasta ~60 %
        Row {
            visible: P.BatteryStore.conservationAvailable
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 8
            opacity: P.BatteryStore.conservationWritable ? 1 : 0.5

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Cargar hasta 60 %"
                color: App.Theme.text
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            C.Switch {
                anchors.verticalCenter: parent.verticalCenter
                checked: P.BatteryStore.conservation
                onToggled: c => P.BatteryStore.setConservation(c)
            }
        }
    }

    // Sin permiso para escribir el archivo del modo conservación
    Text {
        visible: P.BatteryStore.conservationAvailable && !P.BatteryStore.conservationWritable
        width: parent.width
        wrapMode: Text.WordWrap
        text: "Falta el permiso para cambiar «Cargar hasta 60 %»: sudo sh system/conservation-mode.sh"
        color: App.Theme.amber
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
    }

    Rectangle {
        width: parent.width
        height: 1
        color: App.Theme.islandEdge
    }

    // ── Cafeína ──
    Row {
        CC.QuickToggle {
            glyph: String.fromCodePoint(0xf0176)
            text: "No bloquear ni apagar"
            checked: I.IdleStore.caffeine
            activeColor: App.Theme.amber
            onClicked: I.IdleStore.toggleCaffeine()
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: App.Theme.islandEdge
    }

    // ── Perfil de energía ──
    ProfileSection {
        width: parent.width
    }

    Rectangle {
        width: parent.width
        height: 1
        color: App.Theme.islandEdge
    }

    // ── Inactividad ──
    IdleTable {
        width: parent.width
    }

    Item {
        width: parent.width
        height: App.Config.power.rowHeight

        Text {
            width: App.Config.power.labelWidth
            anchors.verticalCenter: parent.verticalCenter
            text: "Brillo al atenuar"
            color: App.Theme.text
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
        }
        C.Slider {
            x: App.Config.power.labelWidth
            width: parent.width - App.Config.power.labelWidth - 44
            anchors.verticalCenter: parent.verticalCenter
            to: 0.5
            value: ST.SettingsStore.idle.dimLevel
            onMoved: v => ST.SettingsStore.idle.dimLevel = Math.max(App.Config.brightness.min, Math.round(v * 100) / 100)
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(ST.SettingsStore.idle.dimLevel * 100) + " %"
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.DemiBold
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: App.Theme.islandEdge
    }

    // ── Avisos de batería baja ──
    BatteryWarnings {
        width: parent.width
    }

    Rectangle {
        width: parent.width
        height: 1
        color: App.Theme.islandEdge
    }

    // ── Restablecer (pide un segundo clic) ──
    Item {
        width: parent.width
        height: App.Config.notifications.headerHeight

        CC.QuickToggle {
            anchors.right: parent.right
            icon: Qt.resolvedUrl("../../../assets/svg/restart.svg")
            text: root.confirmingReset ? "¿Restablecer?" : "Restablecer"
            checked: root.confirmingReset
            activeColor: App.Theme.red
            onClicked: {
                if (root.confirmingReset) {
                    resetTimer.stop();
                    root.confirmingReset = false;
                    ST.SettingsStore.reset();
                } else {
                    root.confirmingReset = true;
                    resetTimer.restart();
                }
            }
        }
    }
}
