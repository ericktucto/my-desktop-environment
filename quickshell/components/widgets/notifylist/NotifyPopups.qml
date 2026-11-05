import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../services/notify/" as S
import "../../../" as App

// Ventana de popups: arriba a la derecha, debajo de la zona reservada por la barra.
PanelWindow {
    id: root

    // Se oculta mientras un panel de la barra está abierto (se abren en la misma zona)
    property bool suppressed: false

    anchors {
        top: true
        right: true
    }
    margins.right: App.Config.bar.marginRight

    implicitWidth: App.Config.notifications.popupWidth
    implicitHeight: column.implicitHeight
    color: "transparent"
    visible: S.NotificationStore.popups.length > 0 && !suppressed

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "stixshell-popups"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0

    Column {
        id: column
        spacing: App.Config.notifications.spacing

        Repeater {
            model: ScriptModel {
                values: S.NotificationStore.popups
            }
            delegate: NotifyPopup {}
        }
    }
}
