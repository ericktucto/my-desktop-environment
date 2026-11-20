import QtQuick
import "../../../services/windows/WindowMenu.js" as WM
import "../../../" as App

// Una fila de la isla de la ventana, como la de un menú: ✓ si está activa, el nombre (con su letra
// subrayada), y a la derecha un texto, el atajo en teclas dibujadas o la flecha de un submenú.
Rectangle {
    id: root

    property string label: ""
    // Índice de la letra subrayada (-1 = ninguna)
    property int mnemonic: -1
    property string keys: ""
    property string trailing: ""
    property bool checked: false
    property bool danger: false
    // Rellena la fila de rojo (por ejemplo, «¿Forzar? Clic otra vez»)
    property bool armed: false
    // "›" cerrado, "⌄" abierto, "" = no es un submenú
    property string submenu: ""
    // Fila elegida con el teclado
    property bool selected: false
    // Margen izquierdo para alinear con las filas que llevan ✓
    property bool showCheck: true

    signal clicked

    width: parent ? parent.width : 0
    height: 30
    radius: 10
    opacity: enabled ? 1 : 0.4
    color: armed ? App.Theme.red : (selected || mouse.containsMouse ? App.Theme.surfaceActive : "transparent")

    Text {
        visible: root.showCheck
        x: 8
        width: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.checked ? "✓" : ""
        color: App.Theme.primary
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
        font.weight: Font.DemiBold
    }
    Text {
        anchors.left: parent.left
        anchors.leftMargin: root.showCheck ? 26 : 10
        anchors.right: right.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.StyledText
        text: WM.underline(root.label, root.mnemonic)
        elide: Text.ElideRight
        color: root.armed ? App.Theme.white : (root.danger ? App.Theme.red : App.Theme.white)
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
    }
    Row {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Text {
            visible: root.trailing !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.trailing
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
        KeyCaps {
            anchors.verticalCenter: parent.verticalCenter
            keys: root.keys
        }
        Text {
            visible: root.submenu !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.submenu
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
