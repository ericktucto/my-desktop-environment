import QtQuick
import "../../../services/network/" as NS
import "../../../" as App

// Tarjeta con la configuración de WireGuard u OpenVPN leída (archivo, QR o portapapeles): nombre editable, un
// resumen (tipo, servidor, qué tráfico pasa por la VPN), usuario y contraseña si el .ovpn los pide, y [Cancelar] [Agregar].
Rectangle {
    id: root

    readonly property var pending: NS.NetworkStore.pending

    implicitHeight: col.implicitHeight + 28
    radius: 18
    color: App.Theme.surfaceActive
    border.width: 1
    border.color: App.Theme.primary

    onPendingChanged: {
        if (pending) {
            nameInput.text = pending.name;
            nameInput.forceActiveFocus();
            nameInput.selectAll();
        }
    }

    readonly property bool openvpn: pending !== null && pending.type === "openvpn"
    readonly property bool needsAuth: openvpn && pending.needsAuth

    onNeedsAuthChanged: {
        userInput.text = "";
        passInput.text = "";
        passInput.showText = false;
    }

    function add() {
        if (nameInput.text.trim() === "")
            return;
        if (needsAuth && (userInput.text.trim() === "" || passInput.text === "")) {
            (userInput.text.trim() === "" ? userInput : passInput).focusInput();
            return;
        }
        NS.NetworkStore.confirmImport(nameInput.text, userInput.text.trim(), passInput.text);
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 8

        Text {
            text: root.openvpn ? "Agregar VPN de OpenVPN" : "Agregar VPN de WireGuard"
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.DemiBold
        }

        Rectangle {
            width: parent.width
            height: 36
            radius: 10
            color: "transparent"
            border.width: 1
            border.color: nameInput.activeFocus ? App.Theme.primary : App.Theme.surfaceHigh

            TextInput {
                id: nameInput
                anchors.fill: parent
                anchors.margins: 8
                verticalAlignment: TextInput.AlignVCenter
                color: App.Theme.white
                selectionColor: App.Theme.primary
                font.pixelSize: App.Config.fontSize.lg
                maximumLength: 15
                clip: true
                Keys.onReturnPressed: event => {
                    event.accepted = true;
                    root.add();
                }
                Keys.onEnterPressed: event => {
                    event.accepted = true;
                    root.add();
                }
            }
        }

        Text {
            visible: root.pending && root.pending.endpoint !== ""
            width: parent.width
            elide: Text.ElideRight
            text: root.pending ? "Servidor " + root.pending.endpoint : ""
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
        Text {
            visible: root.pending && root.pending.address !== ""
            width: parent.width
            elide: Text.ElideRight
            text: root.pending ? "Dirección " + root.pending.address : ""
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
        Text {
            visible: root.pending !== null
            width: parent.width
            elide: Text.ElideRight
            text: !root.pending ? "" : (root.pending.fullTunnel ? "Todo el tráfico pasa por la VPN (y solo se usa su DNS)" : (root.pending.allowed.length > 0 ? "Solo " + root.pending.allowed.join(", ") : ""))
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
        NetField {
            id: userInput
            visible: root.needsAuth
            width: parent.width
            placeholder: "Usuario"
            onAccepted: passInput.focusInput()
        }
        NetField {
            id: passInput
            visible: root.needsAuth
            width: parent.width
            secret: true
            placeholder: "Contraseña"
            onAccepted: root.add()
        }

        Row {
            anchors.right: parent.right
            spacing: 8

            SmallButton {
                label: "Cancelar"
                onClicked: NS.NetworkStore.cancelImport()
            }
            SmallButton {
                primary: true
                label: "Agregar"
                onClicked: root.add()
            }
        }
    }
}
