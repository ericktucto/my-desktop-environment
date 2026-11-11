import QtQuick
import Quickshell
import "../../../" as App

// Reloj analógico mini (dos agujas) para el círculo del reloj mientras la música está expandida.
Item {
    id: root

    width: App.Config.media.miniClock
    height: width

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property real minuteAngle: clock.date.getMinutes() * 6
    readonly property real hourAngle: (clock.date.getHours() % 12) * 30 + clock.date.getMinutes() * 0.5

    // Aguja: un rectángulo que sale del centro hacia arriba y gira sobre el centro
    component Hand: Rectangle {
        id: hand
        property real angle: 0
        property real handLength: 8
        property real thickness: 1.5

        x: root.width / 2 - thickness / 2
        y: root.height / 2 - handLength
        width: thickness
        height: handLength
        radius: thickness / 2
        color: App.Theme.white
        antialiasing: true
        transform: Rotation {
            origin.x: thickness / 2
            origin.y: handLength
            angle: hand.angle
        }
    }

    Hand {
        angle: root.hourAngle
        handLength: root.width * 0.26
        thickness: 2
    }
    Hand {
        angle: root.minuteAngle
        handLength: root.width * 0.38
        thickness: 1.5
    }

    Rectangle {
        anchors.centerIn: parent
        width: 3
        height: 3
        radius: 1.5
        color: App.Theme.white
    }
}
