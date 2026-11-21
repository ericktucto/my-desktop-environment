import QtQuick
import "../../../" as App

// Íconos de apps (Noctalia/DMS): el ícono de la app de cada workspace (hasta 3, pequeños); los vacíos son un punto
// y el activo lleva fondo de acento.
WsStyle {
    id: root

    readonly property int icon: 16

    implicitWidth: row.implicitWidth
    implicitHeight: 24
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
                id: cell
                required property var modelData
                readonly property bool hovered: root.hoverId === modelData.id
                readonly property var shownApps: modelData.apps.slice(0, 3)

                width: Math.max(24, icons.implicitWidth + 12)
                height: 24
                radius: 12
                color: modelData.active ? Qt.rgba(App.Theme.primary.r, App.Theme.primary.g, App.Theme.primary.b, 0.35) : (hovered ? App.Theme.surfaceActive : "transparent")
                border.width: modelData.active ? 1 : 0
                border.color: App.Theme.primary
                opacity: modelData.extra ? 0.5 : 1
                Behavior on width {
                    NumberAnimation {
                        duration: App.Config.anim.pill
                        easing.type: Easing.OutCubic
                    }
                }

                // Vacío: un punto
                Rectangle {
                    visible: cell.shownApps.length === 0
                    anchors.centerIn: parent
                    width: 6
                    height: 6
                    radius: 3
                    color: cell.modelData.active ? App.Theme.primary : App.Theme.gray
                }
                Row {
                    id: icons
                    anchors.centerIn: parent
                    spacing: 2
                    Repeater {
                        model: cell.shownApps
                        Image {
                            required property var modelData
                            width: root.icon
                            height: root.icon
                            source: modelData.icon
                            sourceSize: Qt.size(root.icon, root.icon)
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                }
            }
        }
    }
}
