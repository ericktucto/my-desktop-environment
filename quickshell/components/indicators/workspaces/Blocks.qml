import QtQuick
import "../../../" as App

// Bloques (i3/waybar): un rectángulo redondeado con el número; el activo relleno de acento, los ocupados con borde
// y los vacíos atenuados.
WsStyle {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: 20
    rowItem: row
    rep: itemsRep

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            id: itemsRep
            model: root.items
            delegate: Rectangle {
                required property var modelData
                readonly property bool hovered: root.hoverId === modelData.id
                width: 22
                height: 20
                radius: 6
                color: modelData.active ? App.Theme.primary : (hovered ? App.Theme.surfaceActive : "transparent")
                border.width: modelData.active ? 0 : 1
                border.color: modelData.occupied ? App.Theme.white : "transparent"
                opacity: modelData.extra ? 0.5 : 1
                Behavior on color {
                    ColorAnimation {
                        duration: App.Config.anim.hover
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: parent.modelData.id
                    color: parent.modelData.active ? App.Theme.onPrimary : (parent.modelData.occupied || parent.hovered ? App.Theme.white : App.Theme.gray)
                    font.family: App.Config.fonts.mono
                    font.pixelSize: App.Config.fontSize.sm
                    font.weight: parent.modelData.active ? Font.Bold : Font.Medium
                }
            }
        }
    }
}
