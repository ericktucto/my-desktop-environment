import QtQuick
import "../../services/lock/" as L
import "../../" as App

// Campo de contraseña de la pantalla de bloqueo (Enter envía, Esc borra).
Column {
    id: root

    readonly property var cfg: App.Config.lock
    readonly property bool error: L.LockStore.state === "error"
    readonly property bool checking: L.LockStore.state === "checking"
    readonly property bool caps: L.LockStore.capsLock
    readonly property bool numpad: L.LockStore.numpadHint
    // Teclas del bloque numérico que llegan como flechas, Inicio… con Bloq Num apagado
    readonly property var numpadKeys: [Qt.Key_Insert, Qt.Key_End, Qt.Key_Down, Qt.Key_PageDown, Qt.Key_Left, Qt.Key_Clear, Qt.Key_Right, Qt.Key_Home, Qt.Key_Up, Qt.Key_PageUp, Qt.Key_Delete]
    // Línea de estado: el error o "Verificando…" y los avisos de las teclas
    readonly property string status: {
        const parts = [];
        if (error)
            parts.push("Contraseña incorrecta");
        else if (checking)
            parts.push("Verificando…");
        if (caps)
            parts.push("Bloq Mayús activado");
        if (numpad)
            parts.push("Bloq Num desactivado");
        return parts.join(" · ");
    }
    readonly property bool hint: !checking && (caps || numpad)

    spacing: 10

    Rectangle {
        id: field
        width: root.cfg.fieldWidth
        height: root.cfg.fieldHeight
        radius: height / 2
        color: App.Theme.island
        border.width: 2
        border.color: root.error ? App.Theme.red : (root.caps ? App.Theme.amber : (input.activeFocus ? App.Theme.primary : App.Theme.border))

        Behavior on border.color {
            ColorAnimation {
                duration: App.Config.anim.control
            }
        }

        transform: Translate {
            id: shake
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            echoMode: TextInput.Password
            passwordCharacter: "•"
            readOnly: root.checking
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.lg
            clip: true
            focus: true

            Keys.onReturnPressed: L.LockStore.submit(text)
            Keys.onEnterPressed: L.LockStore.submit(text)
            Keys.onEscapePressed: text = ""
            // Escribir de nuevo quita el aviso de error
            onTextEdited: L.LockStore.clearError()
            onTextChanged: {
                if (text === "")
                    L.LockStore.clearNumpad();
            }
            // Bloq Mayús y Bloq Num (el evento sigue su camino) y el teclado numérico con Bloq Num apagado
            Keys.onPressed: event => {
                L.LockStore.keyPressed(event.key);
                if (event.modifiers & Qt.KeypadModifier)
                    L.LockStore.noteNumpad(root.numpadKeys.indexOf(event.key) >= 0);
            }

            Component.onCompleted: forceActiveFocus()
        }

        Text {
            anchors.centerIn: parent
            visible: input.text === ""
            text: "Contraseña…"
            color: App.Theme.placeholder
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.lg
        }

        // Al fallar: sacudida y campo vacío
        Connections {
            target: L.LockStore
            function onFailuresChanged() {
                input.text = "";
                input.forceActiveFocus();
                shakeAnim.restart();
            }
        }

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: shake; property: "x"; to: -14; duration: root.cfg.errorShake / 6 }
            NumberAnimation { target: shake; property: "x"; to: 14; duration: root.cfg.errorShake / 3 }
            NumberAnimation { target: shake; property: "x"; to: -8; duration: root.cfg.errorShake / 3 }
            NumberAnimation { target: shake; property: "x"; to: 0; duration: root.cfg.errorShake / 6 }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        height: App.Config.fontSize.md + 4
        spacing: 6

        Text {
            visible: root.hint
            text: String.fromCodePoint(root.caps ? 0xf0632 : 0xf03a0)
            color: App.Theme.amber
            font.family: App.Config.fonts.icons
            font.pixelSize: App.Config.fontSize.md + 2
        }
        Text {
            text: root.status
            color: root.error ? App.Theme.red : (root.hint ? App.Theme.amber : App.Theme.gray)
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
        }
    }
}
