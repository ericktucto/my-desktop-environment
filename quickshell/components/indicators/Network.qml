import QtQuick
import "../base" as Base
import "../widgets/network/" as NW
import "../../services/network/" as NS
import "../../services/settings/" as ST
import "../../" as App

// Red en la barra: intensidad de la señal (o cable) y un candado con la VPN activa. Se oculta con el Wi-Fi
// apagado y sin cable. Un clic la expande, bajo el ícono, con el panel de red (como los satélites): señal, IP,
// puerta de enlace, DNS y MAC, y los botones. La vista de administración de redes sigue en el centro de control
// (botón «Abrir redes»). Con la pill plegada no se lee ni se consulta nada.
Base.Island {
    id: root

    readonly property var store: NS.NetworkStore

    expandedWidth: App.Config.panel.networkWidth
    expandedHeight: panel.implicitHeight + 2 * paddingContainer
    paddingContainer: App.Config.media.padding
    // El panel toma el foco por su cuenta (teclado)
    preventFocus: true
    // Esc: cierra primero el QR
    escapeBack: function () {
        if (!root.store.share)
            return false;
        root.store.closeShare();
        return true;
    }

    visible: ST.SettingsStore.pills.network && (store.online || store.enabled || expanded)

    // Los datos en vivo solo se leen con el panel abierto
    onOpened: store.panelOpen = true
    onClosed: {
        store.panelOpen = false;
        store.viewKind = "";
    }

    // Abrir o cerrar el panel desde el IPC
    Connections {
        target: root.store
        function onTogglePanel() {
            if (root.expanded)
                root.close();
            else
                root.open();
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.store.barGlyph
        color: root.store.alert ? App.Theme.amber : (root.store.online ? App.Theme.white : App.Theme.grayDark)
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.icon
    }
    Text {
        visible: root.store.vpnActive
        anchors.verticalCenter: parent.verticalCenter
        text: String.fromCodePoint(App.Config.network.glyphLock)
        color: App.Theme.green
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.icon
    }

    body: NW.NetworkMiniPanel {
        id: panel
        width: parent ? parent.width : 0
        islandRadius: root.radiusExpanded
        onCloseRequested: root.close()
    }
}
