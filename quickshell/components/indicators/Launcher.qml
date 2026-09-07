import QtQuick
import Quickshell
import "../base" as Base
import "../../" as App

Base.Island {
    expandedHeight: 80
    expandedWidth: 360
    radiusExpanded: 32
    Text {
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: App.Theme.white
        font.family: "JetBrains Mono"
        font.pixelSize: 13
        font.weight: Font.Medium
        anchors.verticalCenter: parent.verticalCenter
    }

    body: Rectangle {
        Text {
            text: "Hola Erick"
            color: App.Theme.white
        }
    }

    // El SystemClock vive AQUÍ, dentro del componente Clock
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
