import QtQuick
import "../../controls/" as C
import "../../../" as App

// Botón de interruptor rápido (No molestar, y más adelante Wi-Fi, Bluetooth…).
Rectangle {
    id: root

    property url icon
    property string text
    property bool checked: false

    signal clicked

    height: App.Config.notifications.headerHeight
    width: row.implicitWidth + 2 * 16
    radius: height / 2
    color: checked ? App.Theme.primary : App.Theme.surface

    Behavior on color {
        ColorAnimation {
            duration: App.Config.anim.control
        }
    }

    // Aclara el fondo con el hover
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: mouse.containsMouse ? App.Theme.surfaceHover : "transparent"
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        C.IconSvg {
            anchors.verticalCenter: parent.verticalCenter
            source: root.icon
            size: App.Config.notifications.headerIconSize
            color: App.Theme.white
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
