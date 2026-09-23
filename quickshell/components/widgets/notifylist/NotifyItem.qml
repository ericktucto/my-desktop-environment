import QtQuick
import QtQuick.Effects
import Quickshell.Services.Notifications
import "../../../services/notify/" as N
import "../../../" as App

Rectangle {
    id: root

    required property Notification modelData
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

        Image {
            id: img
            width: 48
            height: 48
            source: root.modelData.image
            sourceSize {
                width: 48
                height: 48
            }
            fillMode: Image.PreserveAspectFit

            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                maskSource: maskRect
            }
        }

        Rectangle {
            id: maskRect
            visible: false
            layer.enabled: true
            anchors.fill: img
            radius: 8
        }

        Column {
            x: img.visible ? 72 : 12
            width: parent.width - x - 12
            spacing: 2

            Text {
                text: root.modelData?.summary
                color: "white"
                font.bold: true
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: root.modelData?.body ?? ''
                color: App.Theme.white
                font.pixelSize: 11
                elide: Text.ElideRight
                maximumLineCount: 1
                width: parent.width
                visible: text !== ""
            }
        }
        Rectangle {
            id: close
            x: 300
            width: 24
            height: 24
            color: App.Theme.grayDark
            opacity: 0.5
            radius: 12

            Text {
                anchors.fill: parent
                text: 'x'
                color: 'white'
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            MouseArea {
                id: mouseClose
                z: 10
                anchors.fill: parent
                hoverEnabled: true
                onClicked: N.NotificationStore.dismiss(root.modelData)
            }
        }
    }
}
