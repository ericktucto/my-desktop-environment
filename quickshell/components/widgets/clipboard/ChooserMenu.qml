import QtQuick
import Quickshell
import "../../../" as App

// Lista corta de opciones { name, icon | glyph } (Abrir con, Compartir). Emite `chosen(item)`.
Item {
    id: root

    property var items: []
    property bool ready: true
    property string emptyText: ""

    signal chosen(var item)

    // Ruta absoluta o nombre del tema (igual que RowApp)
    function resolveIcon(str) {
        if (!str)
            return "";
        if (str.startsWith("/"))
            return "file://" + str;
        if (str.includes(":"))
            return str;
        return Quickshell.iconPath(str, true);
    }

    ListView {
        anchors.fill: parent
        clip: true
        spacing: 4
        model: root.items
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            required property var modelData

            width: ListView.view.width
            height: 44
            radius: App.Config.radius.md
            color: rowMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface

            Behavior on color {
                ColorAnimation {
                    duration: App.Config.anim.hover
                }
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26

                    Image {
                        anchors.fill: parent
                        visible: modelData.glyph === undefined
                        source: modelData.glyph === undefined ? root.resolveIcon(modelData.icon) : ""
                        sourceSize: Qt.size(52, 52)
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: modelData.glyph !== undefined
                        text: modelData.glyph !== undefined ? String.fromCodePoint(modelData.glyph) : ""
                        color: App.Theme.white
                        font.family: App.Config.fonts.icons
                        font.pixelSize: App.Config.fontSize.iconLg
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 26 - parent.spacing
                    text: modelData.name
                    color: App.Theme.text
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.chosen(modelData)
            }
        }
    }

    Text {
        anchors.centerIn: parent
        width: parent.width
        visible: root.items.length === 0
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: root.ready ? root.emptyText : "Buscando…"
        color: App.Theme.subtext
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.md
    }
}
