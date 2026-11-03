import QtQuick
import "../../" as App

// Switch estilo Material 3: pista redondeada; apagado = borde + círculo pequeño,
// encendido = pista rellena + círculo grande con check.
Item {
    id: root

    property bool checked: false

    signal toggled(bool checked)

    implicitWidth: 40
    implicitHeight: 24

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? App.Theme.primary : "transparent"
        border.width: root.checked ? 0 : 2
        border.color: App.Theme.grayDark

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Rectangle {
        id: thumb
        property real size: root.checked ? 18 : 10
        width: size
        height: size
        radius: size / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 3 : 7 + (10 - width) / 2
        color: root.checked ? App.Theme.white : App.Theme.grayDark

        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on size { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: "✓"
            font.pixelSize: 11
            font.bold: true
            color: App.Theme.primary
            opacity: root.checked ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
