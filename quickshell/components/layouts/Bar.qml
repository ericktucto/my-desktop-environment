import QtQuick
import "../../" as App

Rectangle {
    id: barRow
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: App.Config.bar.exclusiveZone
    color: "transparent"
}
