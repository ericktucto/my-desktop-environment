import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../base" as Base
import "../../" as Root

Base.Island {
    id: root
    collapsedWidth: 115

    // Datos de UPower
    readonly property var battery: UPower.displayDevice
    readonly property int percent: Math.round(battery.percentage * 100)
    readonly property bool charging: battery.state === UPowerDeviceState.Charging

    readonly property string batteryIcon: {
        if (percent <= 20) return String.fromCodePoint(0xf243)
        if (percent <= 50) return String.fromCodePoint(0xf242)
        if (percent <= 85) return String.fromCodePoint(0xf241)
        return String.fromCodePoint(0xf240)
    }

    // Color según estado
    readonly property color iconColor: {
        if (charging || percent >= 85) return Root.Theme.green
        if (percent <= 20) return Root.Theme.red
        if (percent <= 35) return Root.Theme.orange
        return Root.Theme.white
    }

    // Contenido de la pill: ícono + porcentaje
    Row {
        spacing: 10

        Text {
            visible: charging
            text: String.fromCodePoint(0xf140b)
            font.family: "Symbols Nerd Font"   // o el nombre exacto de tu Nerd Font
            font.pixelSize: 16
            color: Root.Theme.yellow
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.batteryIcon
            font.family: "Symbols Nerd Font"   // o el nombre exacto de tu Nerd Font
            font.pixelSize: 16
            color: root.iconColor
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.percent + "%"
            font.family: "Inter"   // o el nombre exacto de tu Nerd Font
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.letterSpacing: -1

            color: "#e8eaed"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
