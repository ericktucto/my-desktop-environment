import QtQuick
import "../../" as App

Item {
    id: root

    property real value: 0      // 0..to
    property real to: 1.0
    property bool enabled: true

    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 18

    readonly property real ratio: to > 0 ? Math.max(0, Math.min(1, value / to)) : 0

    // Pista
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: App.Theme.grayDark

        // Relleno
        Rectangle {
            width: parent.width * root.ratio
            height: parent.height
            radius: parent.radius
            color: App.Theme.primary
        }

        // Marca del 100% cuando el rango llega a 150%
        Rectangle {
            visible: root.to > 1.0
            x: parent.width * (1.0 / root.to) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 10
            color: App.Theme.gray
        }
    }

    // Tirador
    Rectangle {
        width: 12
        height: 12
        radius: 6
        color: App.Theme.white
        anchors.verticalCenter: parent.verticalCenter
        x: (root.width - width) * root.ratio
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor

        function update(mouseX) {
            const r = Math.max(0, Math.min(1, mouseX / width));
            root.moved(r * root.to);
        }

        onPressed: mouse => update(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                update(mouse.x);
        }
    }
}
