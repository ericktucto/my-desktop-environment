import QtQuick
import Quickshell
import "../../../services/media/" as M
import "../../../" as App

// Fichas para elegir el reproductor (Firefox, mpv…). Solo se usan con dos o más.
Row {
    id: root

    spacing: 6

    Repeater {
        model: M.MediaStore.players

        Rectangle {
            id: chip

            required property var modelData
            readonly property bool current: modelData === M.MediaStore.player
            readonly property var entry: modelData.desktopEntry !== "" ? DesktopEntries.byId(modelData.desktopEntry) : null

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
                    visible: chip.entry && chip.entry.icon
                    width: 16
                    height: 16
                    source: chip.entry && chip.entry.icon ? Quickshell.iconPath(chip.entry.icon, true) : ""
                    sourceSize: Qt.size(32, 32)
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: chip.modelData.identity
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
                onClicked: M.MediaStore.select(chip.modelData)
            }
        }
    }
}
