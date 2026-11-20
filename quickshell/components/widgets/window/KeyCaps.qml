import QtQuick
import "../../../services/windows/WindowMenu.js" as WM
import "../../../" as App

// Un atajo con cada tecla en su cajita: "SUPER+SHIFT+F" → [Super] [⇧] [F].
Row {
    id: root

    property string keys: ""
    property color textColor: App.Theme.gray

    spacing: 3
    visible: keys !== ""

    Repeater {
        model: WM.keyLabels(root.keys)
        Rectangle {
            required property string modelData
            height: 18
            width: Math.max(18, cap.implicitWidth + 10)
            radius: 5
            color: App.Theme.surface
            border.width: 1
            border.color: App.Theme.islandEdge
            Text {
                id: cap
                anchors.centerIn: parent
                text: parent.modelData
                color: root.textColor
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.xs
            }
        }
    }
}
