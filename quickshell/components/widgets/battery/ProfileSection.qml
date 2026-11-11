import QtQuick
import "../../../services/power/" as P
import "../../../services/settings/" as ST
import "../../../" as App

// Perfil de energía: uno para cuando usa solo la batería y otro para cuando está con el cargador.
// La shell aplica el de la fuente actual.
Column {
    id: root

    readonly property bool onBattery: P.ProfileStore.onBattery

    spacing: 6

    Text {
        text: "PERFIL DE ENERGÍA"
        color: App.Theme.gray
        font.pixelSize: App.Config.fontSize.xs
        font.weight: Font.DemiBold
        font.letterSpacing: 1
        height: 18
        verticalAlignment: Text.AlignVCenter
    }

    // Sin el daemon
    Text {
        visible: !P.ProfileStore.available
        width: parent.width
        wrapMode: Text.WordWrap
        text: "Perfiles no disponibles: power-profiles-daemon no responde."
        color: App.Theme.amber
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
    }

    Repeater {
        model: [
            {
                key: "battery",
                label: "Con batería"
            },
            {
                key: "ac",
                label: "Con cargador"
            }
        ]

        Column {
            id: block

            required property var modelData
            readonly property bool current: (modelData.key === "battery") === root.onBattery

            visible: P.ProfileStore.available
            width: root.width
            spacing: 4

            Text {
                text: block.modelData.label + (block.current ? " · ahora" : "")
                color: block.current ? App.Theme.white : App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
                font.weight: Font.Medium
            }
            ProfileSelector {
                width: parent.width
                active: block.current
                current: ST.SettingsStore.profiles[block.modelData.key]
                onPicked: key => ST.SettingsStore.profiles[block.modelData.key] = key
            }
        }
    }

    // Cambiado por fuera (Fn+Q, powerprofilesctl, una app) y límites del daemon
    Text {
        visible: text !== ""
        width: parent.width
        wrapMode: Text.WordWrap
        text: P.ProfileStore.overrideText
        color: App.Theme.amber
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
    }
    Text {
        visible: P.ProfileStore.available && text !== ""
        width: parent.width
        wrapMode: Text.WordWrap
        text: P.ProfileStore.degradedText
        color: App.Theme.orange
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
    }
}
