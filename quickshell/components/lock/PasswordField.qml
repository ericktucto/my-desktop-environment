import QtQuick
import "../../services/lock/" as L
import "../../" as App

// Campo de contraseña de la pantalla de bloqueo (Enter envía, Esc borra).
Column {
    id: root

    readonly property var cfg: App.Config.lock
    readonly property bool error: L.LockStore.state === "error"
    readonly property bool checking: L.LockStore.state === "checking"

    spacing: 10

    Rectangle {
        id: field
        width: root.cfg.fieldWidth
        height: root.cfg.fieldHeight
        radius: height / 2
        color: App.Theme.island
        border.width: 2
        border.color: root.error ? App.Theme.red : (input.activeFocus ? App.Theme.primary : App.Theme.islandEdge)

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

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        height: App.Config.fontSize.md + 4
        text: root.error ? "Contraseña incorrecta" : (root.checking ? "Verificando…" : "")
        color: root.error ? App.Theme.red : App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.md
    }
}
