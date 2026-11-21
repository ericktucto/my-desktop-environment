import QtQuick
import "../../../" as App

// Botón pequeño en forma de pastilla (Cancelar, Agregar, Conectar…).
Rectangle {
    id: root

    property string label: ""
    property bool primary: false

    signal clicked

    width: text.implicitWidth + 32
    height: 32
    radius: 16
    color: primary ? (mouse.containsMouse ? Qt.lighter(App.Theme.primary, 1.12) : App.Theme.primary) : (mouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface)

    Text {
        id: text
        anchors.centerIn: parent
        text: root.label
        color: root.primary ? App.Theme.onPrimary : App.Theme.white
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
