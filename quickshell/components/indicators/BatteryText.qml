import QtQuick
import Quickshell.Services.UPower
import "../../" as App

Row {

    // Datos de UPower
    readonly property var battery: UPower.displayDevice
    readonly property int percent: Math.round(battery.percentage * 100)
    readonly property bool charging: battery.state === UPowerDeviceState.Charging

    readonly property string batteryIcon: {
        if (percent <= 20)
            return String.fromCodePoint(0xf243);
        if (percent <= 50)
            return String.fromCodePoint(0xf242);
        if (percent <= 85)
            return String.fromCodePoint(0xf241);
        return String.fromCodePoint(0xf240);
    }

    // Color según estado
    readonly property color iconColor: {
        if (charging || percent >= 85)
            return App.Theme.green;
        if (percent <= 20)
            return App.Theme.red;
        if (percent <= 35)
            return App.Theme.orange;
        return App.Theme.white;
    }

    spacing: App.Config.pill.contentSpacing

    // Contenido de la pill: ícono + porcentaje
    Text {
        visible: charging
        text: String.fromCodePoint(0xf140b)
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.icon
        color: App.Theme.yellow
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: batteryIcon
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.icon
        color: iconColor
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: percent + "%"
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
        font.weight: Font.DemiBold
        font.letterSpacing: -1

        color: App.Theme.white
        anchors.verticalCenter: parent.verticalCenter
    }
}
