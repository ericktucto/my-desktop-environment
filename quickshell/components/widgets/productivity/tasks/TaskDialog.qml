import QtQuick
import "../../../../" as App

// Cuadro de diálogo sobre la pestaña Tareas: un título, un texto, un campo opcional y botones.
// Teclas: Enter = el primer botón, la letra de cada botón (`key`) y Esc cancela (lo cierra el panel).
Item {
    id: root

    property string title: ""
    property string message: ""
    // Si no está vacío, se muestra un campo con este texto de ayuda
    property string placeholder: ""
    property bool showInput: false
    // [{ id, label, key (letra de atajo, opcional), danger }]
    property var buttons: []
    readonly property string text: input.text

    signal chosen(string id, string text)

    visible: false
    z: 100

    function open(initial) {
        input.text = initial ?? "";
        visible = true;
        if (showInput)
            input.forceActiveFocus();
        else
            root.forceActiveFocus();
    }

    function close() {
        visible = false;
    }

    function choose(id) {
        const t = input.text;
        close();
        root.chosen(id, t);
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (buttons.length > 0)
                choose(buttons[0].id);
            event.accepted = true;
            return;
        }
        if (showInput)
            return;
        const b = buttons.find(x => x.key && event.text.toLowerCase() === x.key);
        if (b) {
            choose(b.id);
            event.accepted = true;
        }
    }

    // Fondo atenuado: un clic fuera cancela
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        radius: 16
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(380, parent.width - 40)
        height: column.implicitHeight + 32
        radius: 18
        color: App.Theme.island
        border.color: App.Theme.islandEdge
        border.width: 1

        // Evita que el clic dentro del cuadro llegue al fondo
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column
            x: 18
            y: 16
            width: parent.width - 36
            spacing: 12

            Text {
                width: parent.width
                text: root.title
                wrapMode: Text.Wrap
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.lg
                font.weight: Font.DemiBold
            }
            Text {
                visible: root.message !== ""
                width: parent.width
                text: root.message
                wrapMode: Text.Wrap
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
            }
            Rectangle {
                visible: root.showInput
                width: parent.width
                height: 36
                radius: 10
                color: App.Theme.surface
                border.width: 1
                border.color: App.Theme.primary
                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: App.Theme.white
                    selectionColor: App.Theme.primary
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                    clip: true
                    onAccepted: if (root.buttons.length > 0)
                        root.choose(root.buttons[0].id)
                }
                Text {
                    visible: input.text === ""
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    verticalAlignment: Text.AlignVCenter
                    text: root.placeholder
                    color: App.Theme.placeholder
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                }
            }
            Flow {
                width: parent.width
                spacing: 8
                Repeater {
                    model: root.buttons
                    Rectangle {
                        id: button
                        required property var modelData
                        required property int index
                        width: buttonText.implicitWidth + 28
                        height: 32
                        radius: 16
                        color: index === 0 ? (modelData.danger ? App.Theme.red : App.Theme.primary) : (buttonMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface)
                        Text {
                            id: buttonText
                            anchors.centerIn: parent
                            text: button.modelData.label
                            color: App.Theme.white
                            font.family: App.Config.fonts.text
                            font.pixelSize: App.Config.fontSize.sm
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            id: buttonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.choose(button.modelData.id)
                        }
                    }
                }
                Rectangle {
                    width: cancelText.implicitWidth + 28
                    height: 32
                    radius: 16
                    color: cancelMouse.containsMouse ? App.Theme.surfaceActive : "transparent"
                    Text {
                        id: cancelText
                        anchors.centerIn: parent
                        text: "Cancelar"
                        color: App.Theme.gray
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.sm
                    }
                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }
        }
    }
}
