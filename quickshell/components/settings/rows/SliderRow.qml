import QtQuick
import "../../controls/" as C
import "../../../" as App

// Deslizador entre `from` y `to`, con el valor escrito a la derecha (`format` lo convierte a texto).
SettingRow {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real defaultValue: from
    // Redondeo del valor que se emite (0.01 = dos decimales; 1 = enteros)
    property real step: 0.01
    property var format: v => Math.round(v * 100) + " %"

    signal moved(real value)
    // Al soltar el botón (para aplicar una sola vez algo costoso)
    signal released

    controlWidth: 260
    changed: Math.abs(value - defaultValue) > step / 2
    onResetRequested: moved(defaultValue)

    Text {
        width: 52
        horizontalAlignment: Text.AlignRight
        anchors.verticalCenter: parent.verticalCenter
        text: root.format(root.value)
        color: App.Theme.white
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
        font.weight: Font.DemiBold
    }
    C.Slider {
        width: 190
        anchors.verticalCenter: parent.verticalCenter
        to: 1
        value: root.to > root.from ? (root.value - root.from) / (root.to - root.from) : 0
        onMoved: v => root.moved(Math.round((root.from + v * (root.to - root.from)) / root.step) * root.step)
        onReleased: root.released()
    }
}
