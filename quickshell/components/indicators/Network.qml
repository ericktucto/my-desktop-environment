import QtQuick
import "../base" as Base
import "../../services/network/" as NS
import "../../" as App

// Red en la barra: intensidad de la señal (o cable) y un candado con la VPN activa. Se oculta con el Wi-Fi
// apagado y sin cable. Un clic abre la vista de red del centro de control.
Base.Island {
    id: root

    readonly property var store: NS.NetworkStore

    visible: store.online || store.enabled
    openOnClick: false

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.store.barGlyph
        color: root.store.online ? App.Theme.white : App.Theme.grayDark
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

    // parent: root porque los hijos de Island van a un Row (anchors.fill lo rompe)
    MouseArea {
        parent: root
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.store.openPanel()
    }
}
