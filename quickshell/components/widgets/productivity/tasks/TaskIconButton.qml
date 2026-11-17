import QtQuick
import "../../../../" as App

// Botón redondo con un glifo de Nerd Font (buscar, ⋮, +).
Rectangle {
    id: root

    property int glyph: 0
    property bool active: false
    property int size: 28

    signal clicked

    width: size
    height: size
    radius: size / 2
    color: active || mouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface

    Behavior on color {
        ColorAnimation {
            duration: App.Config.anim.hover
        }
    }

    Text {
        anchors.centerIn: parent
        text: String.fromCodePoint(root.glyph)
        color: App.Theme.white
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.icon - 2
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
