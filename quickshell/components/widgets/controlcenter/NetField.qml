import QtQuick
import "../../../" as App

// Campo de texto de los formularios de red: marcador, y con `secret` la contraseña se oculta (el ojo la muestra).
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property bool secret: false
    property bool showText: false
    readonly property alias input: input

    signal accepted

    height: 36
    radius: 10
    color: "transparent"
    border.width: 1
    border.color: input.activeFocus ? App.Theme.primary : App.Theme.surfaceHigh

    function focusInput() {
        input.forceActiveFocus();
    }

    TextInput {
        id: input
        anchors.left: parent.left
        anchors.right: eye.visible ? eye.left : parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10
        anchors.rightMargin: 6
        color: App.Theme.white
        selectionColor: App.Theme.primary
        font.pixelSize: App.Config.fontSize.lg
        echoMode: root.secret && !root.showText ? TextInput.Password : TextInput.Normal
        clip: true
        // Se acepta el evento: si no, Enter llegaría a la vista y activaría otra fila
        Keys.onReturnPressed: event => {
            event.accepted = true;
            root.accepted();
        }
        Keys.onEnterPressed: event => {
            event.accepted = true;
            root.accepted();
        }
    }
    Text {
        visible: input.text === ""
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.placeholder
        color: App.Theme.placeholder
        font.pixelSize: App.Config.fontSize.lg
    }
    Text {
        id: eye
        visible: root.secret
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: String.fromCodePoint(App.Config.network.glyphEye)
        color: root.showText ? App.Theme.primary : App.Theme.gray
        font.family: App.Config.fonts.icons
        font.pixelSize: App.Config.fontSize.icon

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showText = !root.showText
        }
    }
}
