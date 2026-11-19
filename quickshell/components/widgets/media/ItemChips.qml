import QtQuick
import "../../../" as App

// Fichas para elegir entre varios elementos (reproductores, temporizadores…).
// model: [{ key, label, icon }] (icon: ruta de una imagen, opcional). Solo tiene sentido con dos o más.
Row {
    id: root

    property var model: []
    property var currentKey: null

    signal picked(var key)

    spacing: 6

    Repeater {
        model: root.model

        Rectangle {
            id: chip

            required property var modelData
            readonly property bool current: modelData.key === root.currentKey

            height: 26
            width: row.implicitWidth + 20
            radius: height / 2
            color: current ? Qt.alpha(App.Theme.white, 0.22) : (mouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface)

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 6

                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !!chip.modelData.icon
                    width: 16
                    height: 16
                    source: chip.modelData.icon ?? ""
                    sourceSize: Qt.size(32, 32)
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: chip.modelData.label
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                    font.weight: chip.current ? Font.DemiBold : Font.Normal
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(chip.modelData.key)
            }
        }
    }
}
