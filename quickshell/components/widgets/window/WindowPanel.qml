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

    // Teclado: ↑↓ eligen una fila (-1 = ninguna), Enter la ejecuta, Tab cambia de pestaña y las letras
    // subrayadas (o 1–9) ejecutan la fila
    property int cursor: -1
    focus: true
    onTabChanged: cursor = -1

    function move(step) {
        const es = page.item?.entries ?? [];
        if (es.length === 0)
            return;
        let i = cursor;
        for (let n = 0; n < es.length; n++) {
            i = i < 0 ? (step > 0 ? 0 : es.length - 1) : (i + step + es.length) % es.length;
            if (es[i].enabled !== false) {
                cursor = i;
                return;
            }
        }
    }

    Keys.onPressed: event => {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            return;
        const k = event.key;
        if (k === Qt.Key_Tab || k === Qt.Key_Backtab) {
            tab = tab === "app" ? "window" : "app";
        } else if (k === Qt.Key_Down) {
            move(1);
        } else if (k === Qt.Key_Up) {
            move(-1);
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            const e = (page.item?.entries ?? [])[cursor];
            if (!e)
                return;
            page.item.activate(e);
        } else if (event.text !== "" && page.item?.handleKey(event.text.toLowerCase())) {
            // la tecla ya hizo su acción
        } else {
            return;
        }
        event.accepted = true;
    }

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
            onLoaded: item.cursor = Qt.binding(() => root.cursor)
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
