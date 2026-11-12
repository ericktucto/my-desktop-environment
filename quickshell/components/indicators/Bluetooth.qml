import QtQuick
import "../base" as Base
import "../../services/bluetooth/" as BT
import "../../" as App

// Bluetooth en la barra: solo se ve con algo conectado. Muestra la batería si es un único dispositivo que la
// informa. Un clic abre la vista de Bluetooth del centro de control.
Base.Island {
    id: root

    readonly property var store: BT.BluetoothStore

    visible: store.connected.length > 0
    openOnClick: false

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: String.fromCodePoint(0xf00b1)
        color: App.Theme.primary
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.icon
    }
    Text {
        visible: root.store.batteryDevice !== null
        anchors.verticalCenter: parent.verticalCenter
        text: root.store.batteryDevice ? root.store.percent(root.store.batteryDevice) + "%" : ""
        color: App.Theme.white
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
        font.weight: Font.DemiBold
        font.letterSpacing: -1
    }

    // parent: root porque los hijos de Island van a un Row (anchors.fill lo rompe)
    MouseArea {
        parent: root
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.store.openPanel()
    }
}
