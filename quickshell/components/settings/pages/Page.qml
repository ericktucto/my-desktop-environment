import QtQuick
import QtQuick.Controls
import "../../../" as App

// Base de una página de Preferencias: título y las filas (hijos) en una columna con scroll.
// Las filas (SettingRow) buscan a su página subiendo por los padres hasta `isSettingsPage`.
Item {
    id: root

    readonly property bool isSettingsPage: true
    property string pageId: ""
    property string pageName: ""
    // Texto bajo el título
    property string subtitle: ""

    default property alias rows: col.data

    // Desplaza la página hasta dejar la fila a la vista (al llegar desde el buscador)
    function reveal(item) {
        const y = item.mapToItem(col, 0, 0).y;
        flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, y - 60));
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: header.height + col.height + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: bar
            policy: ScrollBar.AsNeeded
            width: 6
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: bar.pressed ? App.Theme.white : App.Theme.gray
                opacity: bar.active || bar.pressed ? 0.9 : 0.4
            }
            background: Item {}
        }

        Column {
            id: header
            width: parent.width - 16
            spacing: 4
            Text {
                text: root.pageName
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }
            Text {
                visible: root.subtitle !== ""
                width: parent.width
                text: root.subtitle
                wrapMode: Text.WordWrap
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
        }

        Column {
            id: col
            y: header.height + 10
            width: parent.width - 16
            spacing: 8
        }
    }
}
