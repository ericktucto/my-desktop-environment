import QtQuick
import "../base" as Base
import "../widgets/battery/" as B
import "../../services/idle/" as I
import "../../" as App

// Pill de batería: porcentaje y, con la cafeína encendida, una taza.
// Al abrirla es el panel de energía (estado, inactividad y avisos de batería baja).
Base.Island {
    id: root

    expandedWidth: App.Config.panel.batteryWidth
    expandedHeight: panel.implicitHeight + 2 * paddingContainer

    preventFocus: true

    BatteryText {}

    // Cafeína activa: la inactividad está pausada
    Text {
        visible: I.IdleStore.caffeine
        anchors.verticalCenter: parent.verticalCenter
        text: String.fromCodePoint(0xf0176)
        color: App.Theme.amber
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.icon
    }

    body: B.PowerPanel {
        id: panel
        width: parent ? parent.width : 0
    }
}
