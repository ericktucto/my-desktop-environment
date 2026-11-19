import QtQuick
import QtQuick.Shapes
import "../../../" as App

// Anillo de progreso: una pista y un arco que empieza arriba. Lo usan la pill de música (la carátula) y el
// anillo grande del temporizador.
Shape {
    id: root

    property real value: 0                       // 0..1
    property real ringWidth: App.Config.media.ringWidth
    property color trackColor: App.Theme.track
    property color color: App.Theme.primary

    readonly property real r: (Math.min(width, height) - ringWidth) / 2

    layer.enabled: true
    layer.samples: 4

    ShapePath {
        strokeWidth: root.ringWidth
        strokeColor: root.trackColor
        fillColor: "transparent"
        PathAngleArc {
            centerX: root.width / 2
            centerY: root.height / 2
            radiusX: root.r
            radiusY: root.r
            startAngle: 0
            sweepAngle: 360
        }
    }
    ShapePath {
        strokeWidth: root.ringWidth
        strokeColor: root.color
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathAngleArc {
            centerX: root.width / 2
            centerY: root.height / 2
            radiusX: root.r
            radiusY: root.r
            startAngle: -90
            sweepAngle: 360 * Math.max(0.001, Math.min(1, root.value))
        }
    }
}
