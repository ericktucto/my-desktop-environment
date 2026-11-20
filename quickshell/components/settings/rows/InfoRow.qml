import QtQuick
import "../../../" as App

// Una fila de solo lectura: `value` a la derecha (en `valueColor`).
SettingRow {
    id: root

    property string value: ""
    property color valueColor: App.Theme.gray

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 440)
        elide: Text.ElideRight
        text: root.value
        color: root.valueColor
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
        font.weight: Font.Medium
    }
}
