import QtQuick
import Quickshell
import "../../" as App

// Lista de entradas de un menú del tray. Los submenús se despliegan en línea
// (se carga esta misma lista dentro de la entrada con un Loader).
Column {
    id: root

    // QsMenuHandle (menú raíz) o QsMenuEntry (submenú) del que se leen los hijos
    property var source

    // Se emite al activar una entrada final: el popup se cierra
    signal activated

    // Quita el markup y la marca de mnemónico (<u>A</u>…, _Abrir…, &Salir)
    function clean(text) {
        return (text || "").replace(/<[^>]*>/g, "").replace(/&amp;/g, "&").replace(/^[_&]/, "");
    }

    QsMenuOpener {
        id: opener
        menu: root.source
    }

    Repeater {
        model: opener.children

        delegate: Column {
            id: entryItem

            required property var modelData
            property bool expanded: false

            width: root.width

            // Separador o fila de entrada
            Item {
                width: parent.width
                height: entryItem.modelData.isSeparator ? 9 : App.Config.tray.menuItemHeight
                implicitWidth: entryItem.modelData.isSeparator ? 0 : rowContent.implicitWidth + 2 * 10

                Rectangle {
                    visible: entryItem.modelData.isSeparator
                    anchors.centerIn: parent
                    width: parent.width - 8
                    height: 1
                    color: App.Theme.islandEdge
                }

                Rectangle {
                    visible: !entryItem.modelData.isSeparator
                    anchors.fill: parent
                    radius: App.Config.radius.md
                    color: hover.containsMouse && entryItem.modelData.enabled ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                }

                Row {
                    id: rowContent
                    visible: !entryItem.modelData.isSeparator
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    opacity: entryItem.modelData.enabled ? 1 : 0.4

                    // Marca de checkbox / radio
                    Text {
                        width: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: entryItem.modelData.checkState === Qt.Checked ? (entryItem.modelData.buttonType === 2 ? "●" : "✓") : ""
                        color: App.Theme.primary
                        font.pixelSize: App.Config.fontSize.sm
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.clean(entryItem.modelData.text)
                        color: App.Theme.white
                        font.pixelSize: App.Config.fontSize.sm
                    }
                }

                // Indicador de submenú
                Text {
                    visible: entryItem.modelData.hasChildren
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: String.fromCodePoint(entryItem.expanded ? 0xf078 : 0xf054)
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: App.Config.fontSize.xs
                    color: App.Theme.gray
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    enabled: !entryItem.modelData.isSeparator && entryItem.modelData.enabled
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (entryItem.modelData.hasChildren) {
                            entryItem.expanded = !entryItem.expanded;
                        } else {
                            entryItem.modelData.triggered();
                            root.activated();
                        }
                    }
                }
            }

            // Submenú en línea, con sangría
            Loader {
                active: entryItem.expanded
                visible: active
                x: App.Config.tray.menuIndent
                width: parent.width - App.Config.tray.menuIndent
                source: "TrayMenuList.qml"
                onLoaded: {
                    item.source = Qt.binding(() => entryItem.modelData);
                    item.activated.connect(root.activated);
                }
            }
        }
    }
}
