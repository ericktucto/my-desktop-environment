import QtQuick
import "../../../" as App

// Botón redondo con un glifo (‹ › ↻ ⋮ +).
Rectangle {
    id: root

    property int glyph: 0
    property bool spinning: false
    property bool active: false

    signal clicked

    width: 28
    height: 28
    radius: 14
    color: active ? App.Theme.surfaceActive : (mouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface)

    Behavior on color {
        ColorAnimation {
            duration: App.Config.anim.hover
        }
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: String.fromCodePoint(root.glyph)
        color: App.Theme.white
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.icon
        // Gira mientras carga y vuelve a su sitio sin saltos
        rotation: 0
        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            running: root.spinning
        }
        onTextChanged: rotation = 0
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
