import QtQuick
import "../../controls/" as C
import "../../../services/nightlight/" as NL
import "../../../services/settings/" as ST
import "../battery/" as BA
import "../../../" as App

// Vista de la luz nocturna: switch, horario (atardecer a amanecer, horas fijas o siempre), horas, temperatura y
// la pausa. Esc la maneja el centro de control (back()).
FocusScope {
    id: root

    signal backRequested

    readonly property var store: NL.NightLightStore
    readonly property var st: ST.SettingsStore.nightLight
    readonly property var cfg: App.Config.nightLight

    onVisibleChanged: {
        if (visible)
            forceActiveFocus();
    }

    component Label: Text {
        color: App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
        font.weight: Font.DemiBold
        font.letterSpacing: 1
    }
    component Note: Text {
        width: parent.width
        wrapMode: Text.WordWrap
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
    }

    PageHeader {
        id: header
        anchors.top: parent.top
        width: parent.width
        title: "Luz nocturna"
        subtitle: root.store.statusText
        checked: root.store.enabled
        switchEnabled: root.store.available
        onBackRequested: root.backRequested()
        onToggled: root.store.setEnabled(!root.store.enabled)
    }

    Column {
        anchors.top: header.bottom
        anchors.topMargin: 14
        width: parent.width
        spacing: 10

        Note {
            visible: !root.store.available
            text: "Instala hyprsunset para usar la luz nocturna."
            color: App.Theme.orange
        }
        Note {
            visible: root.store.startError
            text: "No se pudo iniciar hyprsunset. Se reintenta en un minuto."
            color: App.Theme.orange
        }

        Label {
            text: "HORARIO"
        }
        Flow {
            width: parent.width
            spacing: 6
            Chip {
                label: "Atardecer a amanecer"
                selected: root.st.mode === "sun"
                onClicked: root.store.setMode("sun")
            }
            Chip {
                label: "Horas fijas"
                selected: root.st.mode === "custom"
                onClicked: root.store.setMode("custom")
            }
            Chip {
                label: "Siempre"
                selected: root.st.mode === "always"
                onClicked: root.store.setMode("always")
            }
        }
        Note {
            visible: text !== ""
            text: root.store.scheduleText
            color: App.Theme.gray
        }

        // Horas fijas
        Repeater {
            model: root.st.mode === "custom" ? [
                {
                    key: "start",
                    label: "Desde"
                },
                {
                    key: "end",
                    label: "Hasta"
                }
            ] : []
            delegate: Item {
                id: timeRow
                required property var modelData
                width: parent.width
                height: App.Config.power.rowHeight
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: timeRow.modelData.label
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                }
                BA.Stepper {
                    anchors.right: parent.right
                    text: root.st[timeRow.modelData.key]
                    onDecrement: root.store.stepTime(timeRow.modelData.key, -1)
                    onIncrement: root.store.stepTime(timeRow.modelData.key, 1)
                }
            }
        }

        // Temperatura
        Item {
            width: parent.width
            height: 18
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: "TEMPERATURA"
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.st.temperature + " K · " + root.store.tempWord(root.st.temperature)
                color: App.Theme.white
                font.pixelSize: App.Config.fontSize.sm
                font.weight: Font.DemiBold
            }
        }
        C.Slider {
            width: parent.width
            // Se aplica al soltar: cada cambio reinicia wlsunset
            property real pending: root.st.temperature
            to: root.cfg.tempMax - root.cfg.tempMin
            value: pending - root.cfg.tempMin
            onMoved: v => pending = root.cfg.tempMin + Math.round(v / root.cfg.tempStep) * root.cfg.tempStep
            onReleased: root.store.setTemperature(pending)
        }

        // Pausa
        Row {
            visible: root.store.enabled && root.store.paused
            width: parent.width
            spacing: 10
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Pausada hasta mañana"
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            SmallButton {
                label: "Reanudar"
                onClicked: root.store.resume()
            }
        }
    }
}
