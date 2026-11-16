import QtQuick
import "../base" as Base
import "../../services/screenshot/" as S
import "../../" as App

// Cuenta regresiva del capturador (el retardo de 3 o 5 s), a la derecha del reloj. Un clic la cancela.
// Se oculta justo antes de congelar la pantalla, así no sale en la captura.
Base.Island {
    id: root

    readonly property var store: S.ScreenshotStore

    visible: store.phase === "countdown"
    openOnClick: false

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: String.fromCodePoint(0xf051b)
        color: App.Theme.amber
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.icon
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: String(root.store.count)
        color: App.Theme.white
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
        font.weight: Font.DemiBold
    }

    // parent: root porque los hijos de Island van a un Row (anchors.fill lo rompe)
    MouseArea {
        parent: root
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.store.cancel()
    }
}
