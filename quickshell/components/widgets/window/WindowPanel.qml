import QtQuick
import "../controlcenter/" as CC
import "../../../services/windows/" as WS
import "../../../" as App

// Isla de la ventana activa: arriba el ícono, el nombre y el título con las pestañas App · Ventana, y debajo
// la pestaña elegida. Las acciones van a la ventana que estaba activa al abrir (store.target).
Item {
    id: root

    readonly property var store: WS.ActiveWindowStore

    // "app" (clic izquierdo) o "window" (clic derecho)
    property string tab: "app"

    implicitHeight: col.implicitHeight

    signal closeRequested

    // Esc: true si había algo que cancelar antes de cerrar la isla
    function back() {
        return page.item?.back?.() ?? false;
    }

    Column {
        id: col
        width: parent.width
        spacing: 10

        Item {
            width: parent.width
            height: 40

            Image {
                id: icon
                anchors.verticalCenter: parent.verticalCenter
                source: root.store.icon
                sourceSize: Qt.size(32, 32)
                width: 32
                height: 32
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
            Column {
                anchors.left: icon.right
                anchors.leftMargin: 10
                anchors.right: tabs.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    width: parent.width
                    text: root.store.name
                    elide: Text.ElideRight
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: root.store.title
                    elide: Text.ElideRight
                    color: App.Theme.gray
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                }
            }
            Row {
                id: tabs
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Repeater {
                    model: [
                        {
                            id: "app",
                            label: "App"
                        },
                        {
                            id: "window",
                            label: "Ventana"
                        }
                    ]
                    CC.Chip {
                        required property var modelData
                        height: 28
                        radius: 14
                        label: modelData.label
                        selected: root.tab === modelData.id
                        onClicked: root.tab = modelData.id
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: App.Theme.islandEdge
        }

        Loader {
            id: page
            width: parent.width
            sourceComponent: root.tab === "window" ? windowPage : appPage
        }
    }

    Component {
        id: appPage
        AppPage {
            onCloseRequested: root.closeRequested()
        }
    }
    Component {
        id: windowPage
        WindowPage {
            onCloseRequested: root.closeRequested()
        }
    }
}
