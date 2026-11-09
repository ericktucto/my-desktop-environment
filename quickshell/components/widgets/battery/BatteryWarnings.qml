import QtQuick
import "../../../services/settings/" as ST
import "../../../" as App

// Umbrales de los avisos de batería baja.
Column {
    id: root

    readonly property var rows: [
        {
            key: "warn",
            label: "Aviso"
        },
        {
            key: "critical",
            label: "Crítico"
        },
        {
            key: "suspend",
            label: "Suspender"
        }
    ]

    spacing: 4

    Text {
        text: "BATERÍA BAJA"
        color: App.Theme.gray
        font.pixelSize: App.Config.fontSize.xs
        font.weight: Font.DemiBold
        font.letterSpacing: 1
        height: 18
        verticalAlignment: Text.AlignVCenter
    }

    Repeater {
        model: root.rows

        Item {
            id: row
            required property var modelData
            width: root.width
            height: App.Config.power.rowHeight

            Text {
                width: App.Config.power.labelWidth
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.label
                color: App.Theme.text
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
            }

            Stepper {
                x: App.Config.power.labelWidth
                text: ST.SettingsStore.pctText(ST.SettingsStore.low[row.modelData.key])
                onDecrement: ST.SettingsStore.low[row.modelData.key] = ST.SettingsStore.pctDown(ST.SettingsStore.low[row.modelData.key])
                onIncrement: ST.SettingsStore.low[row.modelData.key] = ST.SettingsStore.pctUp(ST.SettingsStore.low[row.modelData.key])
            }
        }
    }
}
