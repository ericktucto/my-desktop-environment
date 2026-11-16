import QtQuick
import "../../../services/network/" as NS
import "../../../" as App

// Una VPN de NetworkManager: clic = conectar o desconectar; × para borrarla (pide un segundo clic).
Rectangle {
    id: root

    required property var vpn
    property bool selected: false

    readonly property bool active: vpn.state === "activated"
    property bool confirming: false

    height: App.Config.network.rowHeight
    radius: 14
    color: active ? App.Theme.surfaceActive : (selected || mouse.containsMouse ? App.Theme.surfaceHover : "transparent")

    Behavior on color {
        ColorAnimation {
            duration: App.Config.anim.control
        }
    }

    function askForget() {
        if (confirming) {
            confirming = false;
            NS.NetworkStore.removeVpn(vpn);
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
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.confirming = false;
            if (root.vpn.state !== "activating")
                NS.NetworkStore.toggleVpn(root.vpn);
        }
    }

    Text {
        id: glyph
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: String.fromCodePoint(App.Config.network.glyphVpn)
        color: root.active ? App.Theme.primary : App.Theme.white
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.iconLg + 2
    }

    Column {
        anchors.left: glyph.right
        anchors.leftMargin: 12
        anchors.right: forgetButton.visible ? forgetButton.left : parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            width: parent.width
            text: root.vpn.name
            elide: Text.ElideRight
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.DemiBold
        }
        Text {
            width: parent.width
            text: root.confirming ? "¿Borrar? Vuelve a pulsar ×" : (root.active ? "Conectada · clic para desconectar" : (root.vpn.state === "activating" ? "Conectando…" : "Clic para conectar"))
            elide: Text.ElideRight
            color: root.confirming ? App.Theme.orange : App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
    }

    Rectangle {
        id: forgetButton
        visible: mouse.containsMouse || forgetMouse.containsMouse || root.confirming
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
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
}
