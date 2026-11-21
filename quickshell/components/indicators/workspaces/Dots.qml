import QtQuick
import "../../../" as App

// Puntos: el activo se alarga en color primario; los ocupados van rellenos y los vacíos con borde.
WsStyle {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: App.Config.workspaces.dotSize
    rowItem: row
    rep: itemsRep

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: App.Config.workspaces.spacing

        Repeater {
            id: itemsRep
            model: root.items
            delegate: Rectangle {
                id: dot
                required property var modelData
                readonly property bool hovered: root.hoverId === modelData.id

                width: modelData.active ? App.Config.workspaces.activeWidth : App.Config.workspaces.dotSize
                height: App.Config.workspaces.dotSize
                color: modelData.active ? App.Theme.primary : modelData.occupied ? App.Theme.white : (hovered ? App.Theme.surfaceActive : "transparent")
                border.color: App.Theme.white
                border.width: modelData.active ? 0 : 1
                radius: App.Config.workspaces.dotSize
                opacity: modelData.extra ? 0.5 : (hovered && !modelData.active ? 1 : 0.9)

                Behavior on width {
                    NumberAnimation {
                        duration: App.Config.anim.pill
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
