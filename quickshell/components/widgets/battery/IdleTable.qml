import QtQuick
import "../../../services/idle/" as I
import "../../../services/settings/" as ST
import "../../../" as App

// Tiempos de inactividad: una fila por acción y dos columnas (batería y cargador).
Column {
    id: root

    readonly property var cfg: App.Config.power
    readonly property bool onBattery: I.IdleStore.onBattery

    readonly property var rows: [
        {
            key: "dim",
            label: "Atenuar"
        },
        {
            key: "lock",
            label: "Bloquear"
        },
        {
            key: "screenOff",
            label: "Apagar pantalla"
        },
        {
            key: "suspend",
            label: "Suspender"
        }
    ]

    // El atenuado solo se ve si ocurre antes de bloquear
    function dimHidden(src) {
        const c = ST.SettingsStore.idle[src];
        return c.dim > 0 && c.lock > 0 && c.dim >= c.lock;
    }

    spacing: 4

    // ── Encabezado ──
    Item {
        width: parent.width
        height: 18

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "INACTIVIDAD"
            color: App.Theme.gray
            font.pixelSize: App.Config.fontSize.xs
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }
        Text {
            x: root.cfg.labelWidth
            width: root.cfg.stepperWidth
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            text: "Batería"
            color: root.onBattery ? App.Theme.white : App.Theme.gray
            font.pixelSize: App.Config.fontSize.xs
            font.weight: Font.DemiBold
        }
        Text {
            anchors.right: parent.right
            width: root.cfg.stepperWidth
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            text: "Cargador"
            color: root.onBattery ? App.Theme.gray : App.Theme.white
            font.pixelSize: App.Config.fontSize.xs
            font.weight: Font.DemiBold
        }
    }

    // ── Filas ──
    Repeater {
        model: root.rows

        Item {
            id: row
            required property var modelData
            width: root.width
            height: root.cfg.rowHeight

            Text {
                width: root.cfg.labelWidth
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.label
                color: App.Theme.text
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
            }

            Stepper {
                x: root.cfg.labelWidth
                active: root.onBattery
                text: ST.SettingsStore.format(ST.SettingsStore.idle.battery[row.modelData.key])
                onDecrement: ST.SettingsStore.idle.battery[row.modelData.key] = ST.SettingsStore.stepDown(ST.SettingsStore.idle.battery[row.modelData.key])
                onIncrement: ST.SettingsStore.idle.battery[row.modelData.key] = ST.SettingsStore.stepUp(ST.SettingsStore.idle.battery[row.modelData.key])
            }

            Stepper {
                anchors.right: parent.right
                active: !root.onBattery
                text: ST.SettingsStore.format(ST.SettingsStore.idle.ac[row.modelData.key])
                onDecrement: ST.SettingsStore.idle.ac[row.modelData.key] = ST.SettingsStore.stepDown(ST.SettingsStore.idle.ac[row.modelData.key])
                onIncrement: ST.SettingsStore.idle.ac[row.modelData.key] = ST.SettingsStore.stepUp(ST.SettingsStore.idle.ac[row.modelData.key])
            }
        }
    }

    // ── Aviso: atenuar después de bloquear ──
    Text {
        visible: root.dimHidden("battery") || root.dimHidden("ac")
        width: parent.width
        wrapMode: Text.WordWrap
        text: {
            const where = root.dimHidden("battery") && root.dimHidden("ac") ? "con batería y con cargador" : (root.dimHidden("battery") ? "con batería" : "con cargador");
            return "El atenuado no se verá " + where + " (es después de bloquear).";
        }
        color: App.Theme.orange
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
    }
}
