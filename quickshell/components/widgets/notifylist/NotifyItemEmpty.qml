import QtQuick
import "../../../" as App

Rectangle {
    id: root

    required property int index
    property int totalCount: 0

    width: parent?.width ?? 340
    height: 80
    radius: 8

    border.color: App.Theme.grayDark

    color: App.Theme.black

    Item {
        anchors.fill: parent
        anchors.margins: 8
        Text {
            text: 'No tienes notificaciones'
            color: App.Theme.white
            font.bold: true
            width: parent.width
            height: parent.height

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
