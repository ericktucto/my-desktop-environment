import QtQuick
import "../../../services/network/" as NS
import "../../../" as App

// Una red Wi-Fi: señal, nombre, estado y candado. Clic = conectar o desconectar; en una red segura sin guardar
// abre la pantalla de contraseña (WifiPassword). En las guardadas, ⚙ abre sus detalles y × olvida (pide un segundo clic).
// Recibe el nombre y lee la red de store.byName: la fila no se vuelve a crear cuando cambia la señal. Si la red
// desaparece un instante, se queda con la última que vio.
Rectangle {
    id: root

    required property string name
    property bool selected: false

    readonly property var store: NS.NetworkStore
    readonly property var live: store.byName[name]
    property var network: null
    onLiveChanged: if (live)
        network = live
    Component.onCompleted: network = live ?? null

    property bool confirming: false

    readonly property real mainHeight: App.Config.network.rowHeight
    readonly property bool warn: !!network && network.connected && (store.portal || store.limited)
    height: mainHeight
    radius: 14
    clip: true
    color: network && network.connected ? App.Theme.surfaceActive : (selected || mouse.containsMouse ? App.Theme.surfaceHover : "transparent")

    Behavior on height {
        NumberAnimation {
            duration: App.Config.anim.control
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: App.Config.anim.control
        }
    }

    // Supr (o la ×): el primero pide confirmar y el segundo olvida
    function askForget() {
        if (!network || !network.known)
            return;
        if (confirming) {
            confirming = false;
            store.forget(network);
        } else {
            confirming = true;
            confirmTimer.restart();
        }
    }

    Timer {
        id: confirmTimer
        interval: 3000
        onTriggered: root.confirming = false
    }

    MouseArea {
        id: mouse
        anchors.top: parent.top
        width: parent.width
        height: root.mainHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.confirming = false;
            if (root.network)
                root.store.activate(root.network);
        }
    }

    Text {
        id: glyph
        anchors.left: parent.left
        anchors.leftMargin: 14
        y: (root.mainHeight - height) / 2
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: root.network ? root.store.glyphFor(root.network, root.warn) : ""
        color: root.warn ? App.Theme.amber : (root.network && root.network.connected ? App.Theme.primary : App.Theme.white)
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.iconLg + 2
    }

    Column {
        anchors.left: glyph.right
        anchors.leftMargin: 12
        anchors.right: right.left
        anchors.rightMargin: 8
        y: (root.mainHeight - height) / 2
        spacing: 1

        Text {
            width: parent.width
            text: root.name
            elide: Text.ElideRight
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.DemiBold
        }
        Text {
            width: parent.width
            text: root.confirming ? "¿Olvidar? Vuelve a pulsar ×" : (root.network ? root.store.networkStatus(root.network) : "")
            elide: Text.ElideRight
            color: root.confirming ? App.Theme.orange : (root.warn ? App.Theme.amber : App.Theme.gray)
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
    }

    // ⚙ y × (solo guardadas, al pasar el mouse) y candado
    Row {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: 14
        y: (root.mainHeight - height) / 2
        spacing: 6

        Rectangle {
            visible: !!root.network && root.network.known && (mouse.containsMouse || gearMouse.containsMouse || forgetMouse.containsMouse || root.confirming)
            width: 26
            height: 26
            radius: 13
            color: gearMouse.containsMouse ? App.Theme.surfaceActive : "transparent"

            Text {
                anchors.centerIn: parent
                text: String.fromCodePoint(App.Config.network.glyphGear)
                color: App.Theme.gray
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.icon
            }
            MouseArea {
                id: gearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.store.openDetails(root.network)
            }
        }
        Rectangle {
            visible: !!root.network && root.network.known && (mouse.containsMouse || gearMouse.containsMouse || forgetMouse.containsMouse || root.confirming)
            width: 26
            height: 26
            radius: 13
            color: forgetMouse.containsMouse ? App.Theme.surfaceActive : "transparent"

            Text {
                anchors.centerIn: parent
                text: "×"
                color: root.confirming ? App.Theme.orange : App.Theme.gray
                font.pixelSize: 18
            }
            MouseArea {
                id: forgetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.askForget()
            }
        }
        Text {
            visible: !!root.network && !root.store.isOpen(root.network)
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(App.Config.network.glyphLock)
            color: App.Theme.gray
            font.family: App.Config.fonts.icons
            font.pixelSize: App.Config.fontSize.icon
        }
    }
}
