// IconSvg.qml
import QtQuick
import QtQuick.Effects
import "../../" as App

Item {
    id: root

    property url source
    property color color: App.Theme.text
    property real size: 20

    implicitWidth: size
    implicitHeight: size

    Image {
        id: icon
        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(root.size, root.size)
        visible: false
    }

    MultiEffect {
        source: icon
        anchors.fill: icon
        brightness: 1.0          // necesario si el SVG es negro
        colorization: 1.0
        colorizationColor: root.color
    }
}
