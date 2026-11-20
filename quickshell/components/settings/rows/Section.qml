import QtQuick
import "../../../" as App

// Título de un grupo de ajustes dentro de una página.
Item {
    id: root

    property string text: ""

    width: parent ? parent.width : 0
    height: 34

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        text: root.text.toUpperCase()
        color: App.Theme.grayDark
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
    }
}
