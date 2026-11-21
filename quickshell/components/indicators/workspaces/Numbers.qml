import QtQuick
import "../../../services/workspaces/Numerals.js" as Num
import "../../../" as App

// Números con punto: el número de cada workspace y, debajo, un punto si tiene apps. El activo, en color primario.
// numerals: arabic | japanese | roman
WsStyle {
    id: root

    property string numerals: "arabic"

    implicitWidth: row.implicitWidth
    implicitHeight: App.Config.pill.height
    rowItem: row
    rep: itemsRep

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Repeater {
            id: itemsRep
            model: root.items
            delegate: Item {
                id: cell
                required property var modelData
                readonly property bool hovered: root.hoverId === modelData.id
                readonly property color tone: modelData.active ? App.Theme.primary : (modelData.occupied || hovered ? App.Theme.white : App.Theme.gray)

                width: Math.max(10, label.implicitWidth)
                height: root.height
                opacity: modelData.extra ? 0.5 : 1

                Text {
                    id: label
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.round(parent.height / 2 - implicitHeight / 2) - 2
                    text: Num.label(cell.modelData.id, root.numerals)
                    color: cell.tone
                    font.family: App.Config.fonts.mono
                    font.pixelSize: App.Config.fontSize.sm
                    font.weight: cell.modelData.active ? Font.Bold : Font.Medium
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: label.y + label.implicitHeight + 1
                    width: 4
                    height: 4
                    radius: 2
                    color: cell.tone
                    opacity: cell.modelData.occupied ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: App.Config.anim.hover
                        }
                    }
                }
            }
        }
    }
}
