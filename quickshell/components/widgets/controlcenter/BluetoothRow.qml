import QtQuick
import "../../../services/bluetooth/" as BT
import "../../../" as App

// Una fila de la lista de Bluetooth: glifo del tipo, nombre y estado. Clic = conectar, desconectar o emparejar.
// En los emparejados: × para olvidar (pide un segundo clic) y doble clic (o F2) en la fila para renombrar.
Rectangle {
    id: root

    required property var device
    property bool selected: false

    readonly property bool isPaired: device.paired || device.bonded
    property bool renaming: false
    // Esperando el segundo clic de la ×
    property bool confirming: false

    signal rename(string name)

    height: App.Config.bluetooth.rowHeight
    radius: 14
    color: device.connected ? App.Theme.surfaceActive : (selected || mouse.containsMouse ? App.Theme.surfaceHover : "transparent")

    Behavior on color {
        ColorAnimation {
            duration: App.Config.anim.control
        }
    }

    function startRename() {
        if (!isPaired)
            return;
        confirming = false;
        renaming = true;
        nameInput.text = device.name;
        nameInput.forceActiveFocus();
        nameInput.selectAll();
    }

    function cancelRename() {
        renaming = false;
    }

    // Supr (o la ×): el primero pide confirmar y el segundo olvida
    function askForget() {
        if (!isPaired)
            return;
        if (confirming) {
            confirming = false;
            BT.BluetoothStore.forget(device);
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

    // Un clic espera un momento por si viene el segundo (renombrar), para no conectar sin querer
    Timer {
        id: clickTimer
        interval: 230
        onTriggered: BT.BluetoothStore.activate(root.device)
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !root.renaming
        onClicked: {
            root.confirming = false;
            if (root.isPaired)
                clickTimer.restart();
            else
                BT.BluetoothStore.activate(root.device);
        }
        onDoubleClicked: {
            clickTimer.stop();
            root.startRename();
        }
    }

    Text {
        id: glyph
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: BT.BluetoothStore.glyphFor(root.device)
        color: root.device.connected ? App.Theme.primary : App.Theme.white
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
            visible: !root.renaming
            width: parent.width
            text: root.device.name
            elide: Text.ElideRight
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.DemiBold
        }
        // Renombrar: Enter guarda y Esc cancela (Esc llega por PanelStore.escape → ControlCenter.back)
        TextInput {
            id: nameInput
            visible: root.renaming
            width: parent.width
            color: App.Theme.white
            selectionColor: App.Theme.primary
            clip: true
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.DemiBold
            // Se acepta el evento: si no, Enter llegaría a la página y activaría la fila (conectar)
            function finish(event) {
                event.accepted = true;
                root.renaming = false;
                root.rename(text);
            }
            Keys.onReturnPressed: event => finish(event)
            Keys.onEnterPressed: event => finish(event)

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.bottom
                height: 1
                color: App.Theme.primary
            }
        }
        Text {
            width: parent.width
            text: root.confirming ? "¿Olvidar? Vuelve a pulsar ×" : (root.renaming ? "Enter guarda · vacío vuelve al nombre original" : BT.BluetoothStore.deviceStatus(root.device))
            elide: Text.ElideRight
            color: root.confirming ? App.Theme.orange : App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
    }

    // × para olvidar: solo en los emparejados, al pasar el mouse (o esperando confirmación)
    Rectangle {
        id: forgetButton
        visible: root.isPaired && !root.renaming && (mouse.containsMouse || forgetMouse.containsMouse || root.confirming)
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
