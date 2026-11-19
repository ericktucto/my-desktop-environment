import QtQuick
import "../../../services/network/" as NS
import "../../../" as App

// Una fila «etiqueta · valor» del panel de red. Un clic copia el valor (`copyValue`, o el valor mismo).
Item {
    id: root

    property string label
    property string value
    property string copyValue: ""

    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -6
        anchors.rightMargin: -6
        radius: 8
        color: mouse.containsMouse ? App.Theme.surface : "transparent"
    }

    Text {
        id: name
        anchors.verticalCenter: parent.verticalCenter
        width: 68
        text: root.label
        color: App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
    }
    Text {
        anchors.left: name.right
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: App.Theme.white
        elide: Text.ElideRight
        font.family: App.Config.fonts.mono
        font.pixelSize: App.Config.fontSize.sm
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: NS.NetworkStore.copy(root.copyValue !== "" ? root.copyValue : root.value)
    }
}
