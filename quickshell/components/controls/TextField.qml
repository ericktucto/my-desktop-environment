import QtQuick
import './../../' as App

Rectangle {
    id: root
    property string placeholder: ""
    property alias text: input.text

    signal pressedKey(var key)

    width: parent.width
    height: App.Config.launcher.searchHeight
    color: "transparent"
    border.color: input.activeFocus ? App.Theme.primary : App.Theme.surfaceHigh
    border.width: 1
    radius: App.Config.radius.sm

    TextInput {
        id: input
        anchors.fill: parent
        anchors.margins: 10
        color: App.Theme.white
        font.pixelSize: App.Config.fontSize.lg
        verticalAlignment: TextInput.AlignVCenter
        clip: true

        Keys.onReturnPressed: function() {
            pressedKey(Qt.Key_Enter)
        }
        Keys.onDownPressed: function() {
            pressedKey(Qt.Key_Down)
        }
        Keys.onUpPressed: function() {
            pressedKey(Qt.Key_Up)
        }
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.placeholder
        color: App.Theme.placeholder
        font.pixelSize: App.Config.fontSize.lg
        visible: input.text === "" && !input.activeFocus
    }

    function giveFocus() {
        input.forceActiveFocus()
    }
}

