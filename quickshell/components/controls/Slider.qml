import QtQuick
import "../../" as App

// Slider estilo Material 3: tramo activo + barra vertical (handle) + tramo inactivo,
// con un hueco a cada lado del handle y un punto al final del tramo inactivo.
Item {
    id: root

    property real value: 0      // 0..to
    property real to: 1.0
    property bool enabled: true

    signal moved(real value)

    readonly property real ratio: to > 0 ? Math.max(0, Math.min(1, value / to)) : 0
    readonly property int trackHeight: 12
    readonly property int handleWidth: 4
    readonly property int handleHeight: 22
    readonly property int gap: 4
    readonly property color inactiveColor: Qt.rgba(1, 1, 1, 0.14)

    implicitWidth: 200
    implicitHeight: 24

    // Posición del handle (0 .. width - handleWidth)
    readonly property real handleX: (width - handleWidth) * ratio

    // Tramo activo (izquierda redondeada, derecha casi recta)
    Item {
        id: active
        height: root.trackHeight
        width: Math.max(0, root.handleX - root.gap)
        anchors.verticalCenter: parent.verticalCenter
        visible: width > 0

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: App.Theme.primary
        }
        Rectangle {
            anchors.right: parent.right
            width: Math.min(parent.width, parent.height / 2)
            height: parent.height
            radius: 2
            color: App.Theme.primary
        }
    }

    // Tramo inactivo (izquierda casi recta, derecha redondeada)
    Item {
        id: inactive
        height: root.trackHeight
        x: root.handleX + root.handleWidth + root.gap
        width: Math.max(0, root.width - x)
        anchors.verticalCenter: parent.verticalCenter
        visible: width > 0

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: root.inactiveColor
        }
        Rectangle {
            anchors.left: parent.left
            width: Math.min(parent.width, parent.height / 2)
            height: parent.height
            radius: 2
            color: root.inactiveColor
        }
        // Punto al final del tramo
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 3
            radius: 1.5
            color: App.Theme.primary
        }
    }

    // Marca del 100% cuando el rango llega a 150%
    Rectangle {
        visible: root.to > 1.0
        x: root.handleWidth / 2 + (root.width - root.handleWidth) / root.to - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 3
        radius: 1.5
        color: App.Theme.white
        opacity: 0.8
    }

    // Handle
    Rectangle {
        x: root.handleX
        width: root.handleWidth
        height: root.handleHeight
        radius: width / 2
        color: App.Theme.primary
        anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor

        function update(mouseX) {
            const usable = root.width - root.handleWidth;
            const r = usable > 0 ? Math.max(0, Math.min(1, (mouseX - root.handleWidth / 2) / usable)) : 0;
            root.moved(r * root.to);
        }

        onPressed: mouse => update(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                update(mouse.x);
        }
    }
}
