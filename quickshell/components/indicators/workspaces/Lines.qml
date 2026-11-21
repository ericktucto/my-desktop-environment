import QtQuick
import "../../../" as App

// Líneas (GNOME/Android): barritas finas; la activa más larga y de acento; las ocupadas más brillantes.
WsStyle {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: 4
    rowItem: row
    rep: itemsRep

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            id: itemsRep
            model: root.items
            delegate: Rectangle {
                required property var modelData
                readonly property bool hovered: root.hoverId === modelData.id

                width: modelData.active ? 28 : 14
                height: 4
                radius: 2
                color: modelData.active ? App.Theme.primary : App.Theme.white
                opacity: modelData.active ? 1 : (modelData.extra ? 0.25 : modelData.occupied ? 0.85 : (hovered ? 0.6 : 0.3))

                Behavior on width {
                    NumberAnimation {
                        duration: App.Config.anim.pill
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: App.Config.anim.hover
                    }
                }
            }
        }
    }
}
