import QtQuick
import "../../../services/bluetooth/" as BT
import "../../../" as App

// La pregunta que hace BlueZ al emparejar (la trae el agente, scripts/bt-agent.py): confirmar un código,
// escribir un PIN o un passkey, autorizar una conexión, o mostrar un código para escribirlo en el otro equipo.
Rectangle {
    id: root

    readonly property var req: BT.BluetoothStore.request
    readonly property string type: req ? req.type : ""

    implicitHeight: col.implicitHeight + 28
    radius: 18
    color: App.Theme.surfaceActive
    border.width: 1
    border.color: App.Theme.primary

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 10

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            textFormat: Text.StyledText
            text: {
                if (!root.req)
                    return "";
                const n = "«" + root.req.name + "»";
                switch (root.type) {
                case "confirm":
                    return "¿El código <b>" + String(root.req.passkey).padStart(6, "0") + "</b> aparece en " + n + "?";
                case "pin":
                    return "Escribe el PIN de " + n;
                case "passkey":
                    return "Escribe el código de " + n;
                case "authorize":
                    return "¿Permitir que " + n + " se conecte?";
                case "display":
                    return "Escribe <b>" + (root.req.pin !== undefined ? root.req.pin : String(root.req.passkey).padStart(6, "0")) + "</b> en " + n + " y presiona Enter";
                }
                return "";
            }
        }

        // PIN o passkey
        Rectangle {
            visible: root.type === "pin" || root.type === "passkey"
            width: parent.width
            height: 36
            radius: 10
            color: "transparent"
            border.width: 1
            border.color: valueInput.activeFocus ? App.Theme.primary : App.Theme.surfaceHigh

            TextInput {
                id: valueInput
                anchors.fill: parent
                anchors.margins: 8
                verticalAlignment: TextInput.AlignVCenter
                color: App.Theme.white
                font.pixelSize: App.Config.fontSize.lg
                inputMethodHints: root.type === "passkey" ? Qt.ImhDigitsOnly : Qt.ImhNone
                onAccepted: accept.clicked()
                onVisibleChanged: {
                    if (visible) {
                        text = "";
                        forceActiveFocus();
                    }
                }
            }
        }

        Row {
            visible: root.type !== "display"
            anchors.right: parent.right
            spacing: 8

            component Btn: Rectangle {
                id: btn
                property string label
                property bool primary: false
                signal clicked
                width: t.implicitWidth + 32
                height: 32
                radius: 16
                color: primary ? (m.containsMouse ? Qt.lighter(App.Theme.primary, 1.12) : App.Theme.primary) : (m.containsMouse ? App.Theme.surfaceActive : App.Theme.surface)
                Text {
                    id: t
                    anchors.centerIn: parent
                    text: btn.label
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: m
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: btn.clicked()
                }
            }

            Btn {
                label: root.type === "authorize" ? "Rechazar" : "Cancelar"
                onClicked: BT.BluetoothStore.answer(false, "")
            }
            Btn {
                id: accept
                primary: true
                label: root.type === "authorize" ? "Permitir" : "Emparejar"
                onClicked: BT.BluetoothStore.answer(true, valueInput.text)
            }
        }
    }
}
