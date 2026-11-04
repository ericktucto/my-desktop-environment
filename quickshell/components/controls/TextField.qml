import QtQuick
import './../../' as Root

Rectangle {
    id: root
    property string placeholder: ""
    property alias text: input.text

    signal pressedKey(var key)

    width: parent.width
    height: 40
    color: "transparent"
    border.color: input.activeFocus ? Root.Theme.primary : "#3a3f4a"
    border.width: 1
    radius: Root.Config.radius.sm

    TextInput {
        id: input
        anchors.fill: parent
        anchors.margins: 10
        color: "white"
        font.pixelSize: Root.Config.fontSize.lg
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
        color: "#888888"
        font.pixelSize: Root.Config.fontSize.lg
        visible: input.text === "" && !input.activeFocus
    }

    function giveFocus() {
        input.forceActiveFocus()
    }
}

