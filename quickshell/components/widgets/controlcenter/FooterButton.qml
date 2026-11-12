import QtQuick
import "../../../" as App

// Botón redondo de la fila de abajo del centro de control (apagar, ajustes).
Rectangle {
    id: root

    property string glyph: ""

    signal clicked

    width: App.Config.control.footerHeight
    height: width
    radius: width / 2
    color: mouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface

    Behavior on color {
        ColorAnimation {
            duration: App.Config.anim.control
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        color: App.Theme.white
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.iconLg
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
