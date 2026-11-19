import QtQuick
import QtQuick.Effects
import "../../../" as App

// Fondo de un panel de la isla: degradado del color `accent` a la isla, recortado con las esquinas de la
// isla. Con `source` (la carátula) va difuminada y oscurecida encima. Lo usan el reproductor y el temporizador.
Item {
    id: root

    property color accent: App.Theme.primary
    property real islandRadius: App.Config.pill.radiusExpanded
    property url source: ""
    property real blur: App.Config.media.blur
    property int blurMax: App.Config.media.blurMax
    property real dim: App.Config.media.dim

    Item {
        id: bgMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: root.islandRadius
            color: "black"
        }
    }

    Item {
        id: bgContent
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: bgMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.darker(root.accent, 3)
                }
                GradientStop {
                    position: 1
                    color: App.Theme.island
                }
            }
        }
        Image {
            anchors.fill: parent
            source: root.source
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(256, 256)
            visible: status === Image.Ready
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: root.blur
                blurMax: root.blurMax
                brightness: -root.dim
                saturation: 0.2
            }
        }
    }
}
