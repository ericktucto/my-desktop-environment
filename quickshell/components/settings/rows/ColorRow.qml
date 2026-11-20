import QtQuick
import "../../../" as App

// Un color: muestra y texto "#rrggbb" editable. `picked(hex)` cuando el texto es un color válido.
SettingRow {
    id: root

    property string value: "#2979ff"
    property string defaultValue: "#2979ff"

    signal picked(string hex)

    changed: value.toLowerCase() !== defaultValue.toLowerCase()
    onResetRequested: picked(defaultValue)

    Rectangle {
        width: 28
        height: 28
        radius: 14
        anchors.verticalCenter: parent.verticalCenter
        color: root.value
        border.width: 1
        border.color: App.Theme.islandEdge
    }
    Rectangle {
        width: 96
        height: 30
        radius: 8
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        border.width: 1
        border.color: input.activeFocus ? App.Theme.primary : App.Theme.surfaceHigh
        TextInput {
            id: input
            anchors.fill: parent
            anchors.margins: 8
            verticalAlignment: TextInput.AlignVCenter
            text: root.value
            color: App.Theme.white
            selectionColor: App.Theme.primary
            font.family: App.Config.fonts.mono
            font.pixelSize: App.Config.fontSize.sm
            maximumLength: 7
            clip: true
            onTextEdited: {
                if (/^#[0-9a-fA-F]{6}$/.test(text))
                    root.picked(text.toLowerCase());
            }
        }
    }
}
