import QtQuick
import "../../../services/network/" as NS
import "../../../" as App

// Pantalla de contraseña de una red Wi-Fi (reemplaza a la lista, como los detalles): el campo con el ojo,
// "Conectando…" mientras espera, "Contraseña incorrecta" si falla, y [Cancelar] [Conectar]. Enter conecta;
// Esc y ‹ cancelan (NetworkPage.cancelInner). Si conecta, el store la cierra y se vuelve a la lista.
Item {
    id: root

    readonly property var store: NS.NetworkStore
    readonly property var network: store.byName[store.passwordFor] ?? null
    readonly property bool busy: store.pskState === "connecting"
    property bool showPassword: false

    function connectNow() {
        if (busy || !network || keyInput.text.length === 0)
            return;
        store.connectWith(network, keyInput.text);
    }

    onVisibleChanged: {
        if (!visible)
            return;
        showPassword = false;
        keyInput.text = "";
        keyInput.forceActiveFocus();
    }

    // Tras fallar, el campo se vacía y vuelve el foco
    Connections {
        target: root.store
        function onPskErrorChanged() {
            if (root.store.pskError !== "") {
                keyInput.text = "";
                keyInput.forceActiveFocus();
            }
        }
        function onPskStateChanged() {
            if (root.store.pskState === "")
                keyInput.forceActiveFocus();
        }
    }

    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 12

        Rectangle {
            width: parent.width
            height: 44
            radius: 12
            color: "transparent"
            opacity: root.busy ? 0.5 : 1
            border.width: 1
            border.color: keyInput.activeFocus ? App.Theme.primary : App.Theme.surfaceHigh

            TextInput {
                id: keyInput
                anchors.left: parent.left
                anchors.right: eye.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 14
                anchors.rightMargin: 4
                color: App.Theme.white
                font.pixelSize: App.Config.fontSize.lg
                echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                readOnly: root.busy
                clip: true
                // Se acepta el evento: si no, Enter llegaría a la vista y activaría otra fila
                Keys.onReturnPressed: event => {
                    event.accepted = true;
                    root.connectNow();
                }
                Keys.onEnterPressed: event => {
                    event.accepted = true;
                    root.connectNow();
                }
            }
            Text {
                visible: keyInput.text === ""
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "Contraseña"
                color: App.Theme.placeholder
                font.pixelSize: App.Config.fontSize.lg
            }
            Text {
                id: eye
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: String.fromCodePoint(App.Config.network.glyphEye)
                color: root.showPassword ? App.Theme.primary : App.Theme.gray
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.icon

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showPassword = !root.showPassword
                }
            }
        }

        Text {
            width: parent.width
            height: 16
            text: root.busy ? "Conectando…" : (root.network === null ? "La red ya no está al alcance" : root.store.pskError)
            color: root.busy ? App.Theme.gray : App.Theme.amber
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.DemiBold
        }

        Row {
            anchors.right: parent.right
            spacing: 8

            SmallButton {
                label: "Cancelar"
                onClicked: root.store.closePassword()
            }
            SmallButton {
                primary: true
                label: "Conectar"
                enabled: !root.busy && root.network !== null
                opacity: enabled ? 1 : 0.5
                onClicked: root.connectNow()
            }
        }
    }
}
