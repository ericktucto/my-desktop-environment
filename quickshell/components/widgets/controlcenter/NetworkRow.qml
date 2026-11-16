import QtQuick
import "../../../services/network/" as NS
import "../../../" as App

// Una red Wi-Fi: señal, nombre, estado y candado. Clic = conectar o desconectar; en una red segura sin guardar,
// la fila se despliega con el campo de contraseña. En las guardadas, ⚙ abre sus detalles y × olvida (pide un segundo clic).
Rectangle {
    id: root

    required property var network
    property bool selected: false

    readonly property var store: NS.NetworkStore
    readonly property bool asking: store.passwordFor === network.name
    property bool confirming: false
    property bool showPassword: false

    readonly property real mainHeight: App.Config.network.rowHeight
    height: mainHeight + (asking ? 46 : 0)
    radius: 14
    clip: true
    color: network.connected ? App.Theme.surfaceActive : (selected || mouse.containsMouse ? App.Theme.surfaceHover : "transparent")

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

    onAskingChanged: {
        if (asking) {
            showPassword = false;
            keyInput.text = "";
            keyInput.forceActiveFocus();
        }
    }

    // Supr (o la ×): el primero pide confirmar y el segundo olvida
    function askForget() {
        if (!network.known)
            return;
        if (confirming) {
            confirming = false;
            store.forget(network);
        } else {
            confirming = true;
            confirmTimer.restart();
        }
    }

    function connectNow() {
        if (keyInput.text.length > 0)
            store.connectWith(network, keyInput.text);
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
            if (root.asking)
                root.store.passwordFor = "";
            else
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
        text: root.store.glyphFor(root.network)
        color: root.network.connected ? App.Theme.primary : App.Theme.white
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
            text: root.network.name
            elide: Text.ElideRight
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.DemiBold
        }
        Text {
            width: parent.width
            text: root.confirming ? "¿Olvidar? Vuelve a pulsar ×" : root.store.networkStatus(root.network)
            elide: Text.ElideRight
            color: root.confirming ? App.Theme.orange : App.Theme.gray
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
            visible: root.network.known && (mouse.containsMouse || gearMouse.containsMouse || forgetMouse.containsMouse || root.confirming)
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
            visible: root.network.known && (mouse.containsMouse || gearMouse.containsMouse || forgetMouse.containsMouse || root.confirming)
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
            visible: !root.store.isOpen(root.network)
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(App.Config.network.glyphLock)
            color: App.Theme.gray
            font.family: App.Config.fonts.icons
            font.pixelSize: App.Config.fontSize.icon
        }
    }

    // Contraseña: Enter conecta; Esc la cierra (ControlCenter.back)
    Row {
        visible: root.asking
        anchors.left: parent.left
        anchors.leftMargin: 14 + 24 + 12
        anchors.right: parent.right
        anchors.rightMargin: 14
        y: root.mainHeight - 4
        spacing: 8

        Rectangle {
            width: parent.width - connectButton.width - parent.spacing
            height: 36
            radius: 10
            color: "transparent"
            border.width: 1
            border.color: keyInput.activeFocus ? App.Theme.primary : App.Theme.surfaceHigh

            TextInput {
                id: keyInput
                anchors.left: parent.left
                anchors.right: eye.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                anchors.rightMargin: 4
                color: App.Theme.white
                font.pixelSize: App.Config.fontSize.lg
                echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
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
                id: eye
                anchors.right: parent.right
                anchors.rightMargin: 8
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
        SmallButton {
            id: connectButton
            primary: true
            label: "Conectar"
            onClicked: root.connectNow()
        }
    }
}
