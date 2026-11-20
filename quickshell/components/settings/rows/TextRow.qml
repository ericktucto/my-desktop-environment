import QtQuick
import "../../../" as App

// Un texto corto editable: `accepted(text)` al terminar de escribir (Enter o al perder el foco).
SettingRow {
    id: root

    property string value: ""
    property string placeholder: ""
    property real fieldWidth: 160
    property string defaultValue: ""

    signal accepted(string text)

    changed: value !== defaultValue
    onResetRequested: accepted(defaultValue)

    Rectangle {
        width: root.fieldWidth
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
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            clip: true
            onEditingFinished: root.accepted(text)
        }
        Text {
            visible: input.text === ""
            anchors.fill: parent
            anchors.margins: 8
            verticalAlignment: Text.AlignVCenter
            text: root.placeholder
            color: App.Theme.placeholder
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
    }
}
