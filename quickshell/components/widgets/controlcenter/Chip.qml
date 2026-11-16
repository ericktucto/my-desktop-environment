import QtQuick
import "../../../" as App

// Opción de una fila de pastillas ([Automática] [Manual]…); la elegida va rellena.
Rectangle {
    id: root

    property string label: ""
    property bool selected: false

    signal clicked

    width: text.implicitWidth + 24
    height: 30
    radius: 15
    color: selected ? App.Theme.primary : (mouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface)

    Text {
        id: text
        anchors.centerIn: parent
        text: root.label
        color: App.Theme.white
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
        font.weight: Font.DemiBold
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
