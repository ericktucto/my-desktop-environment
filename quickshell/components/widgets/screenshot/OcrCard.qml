import QtQuick
import "../../../services/screenshot/" as S
import "../../../" as App

// Tarjeta del texto leído (modo Texto o el botón del Editor): un código QR o el texto de la imagen, editable
// para corregir lo que tesseract leyó mal. Ctrl+Enter o [Copiar] lo copia y cierra el capturador; Esc la cierra.
Rectangle {
    id: card

    readonly property var store: S.ScreenshotStore
    readonly property bool isQr: store.ocrKind === "qr"
    readonly property bool ready: store.ocrState === "done" && store.ocrText !== ""
    readonly property bool isLink: isQr && /^https?:\/\//.test(edit.text.trim())
    // Alto máximo del texto (el resto de la tarjeta suma ~110 px)
    property real maxTextHeight: 240

    implicitHeight: col.implicitHeight + 28
    radius: 20
    color: App.Theme.island
    border.width: 1
    border.color: App.Theme.border

    signal closeRequested

    function copy() {
        if (ready)
            store.copyText(edit.text);
    }

    // Al terminar de leer, el texto pasa a la caja y se puede editar
    Connections {
        target: card.store
        function onOcrStateChanged() {
            if (card.store.ocrState === "done") {
                edit.text = card.store.ocrText;
                edit.forceActiveFocus();
                edit.cursorPosition = edit.length;
            }
        }
    }

    Column {
        id: col
        x: 14
        y: 14
        width: parent.width - 28
        spacing: 10

        Row {
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: String.fromCodePoint(card.isQr ? 0xf0432 : 0xf113d)
                color: App.Theme.primary
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.iconLg
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: card.isQr ? "Código QR" : "Texto"
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
                font.weight: Font.DemiBold
            }
        }

        // Estado: leyendo, error o sin texto
        Text {
            visible: !card.ready
            width: parent.width
            wrapMode: Text.WordWrap
            text: card.store.ocrState === "reading" ? "Leyendo…" : (card.store.ocrState === "error" ? card.store.ocrError : "No se encontró texto en el área")
            color: card.store.ocrState === "error" ? App.Theme.amber : App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
        }

        // El texto, editable y con desplazamiento
        Rectangle {
            visible: card.ready
            width: parent.width
            height: Math.min(card.maxTextHeight, edit.contentHeight + 20)
            radius: 10
            color: App.Theme.surface
            clip: true

            Flickable {
                id: flick
                anchors.fill: parent
                anchors.margins: 10
                contentWidth: width
                contentHeight: edit.contentHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                TextEdit {
                    id: edit
                    width: flick.width
                    wrapMode: TextEdit.Wrap
                    color: App.Theme.white
                    selectionColor: App.Theme.primary
                    selectedTextColor: App.Theme.white
                    font.family: App.Config.fonts.mono
                    font.pixelSize: App.Config.fontSize.md
                    persistentSelection: true

                    Keys.onEscapePressed: card.closeRequested()
                    Keys.onPressed: function (e) {
                        // Enter baja de línea; Ctrl+Enter copia
                        if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && (e.modifiers & Qt.ControlModifier)) {
                            card.copy();
                            e.accepted = true;
                        }
                    }
                    // Sigue el cursor al escribir
                    onCursorRectangleChanged: {
                        if (cursorRectangle.y < flick.contentY)
                            flick.contentY = cursorRectangle.y;
                        else if (cursorRectangle.y + cursorRectangle.height > flick.contentY + flick.height)
                            flick.contentY = cursorRectangle.y + cursorRectangle.height - flick.height;
                    }
                }
            }
        }

        // Botones
        Row {
            anchors.right: parent.right
            spacing: 8

            component Btn: Rectangle {
                id: b
                property string label: ""
                property bool primary: false
                signal clicked
                height: 32
                width: txt.implicitWidth + 32
                radius: 16
                color: primary ? (bm.containsMouse ? Qt.lighter(App.Theme.primary, 1.12) : App.Theme.primary) : (bm.containsMouse ? App.Theme.surfaceActive : App.Theme.surface)
                Text {
                    id: txt
                    anchors.centerIn: parent
                    text: b.label
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: bm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: b.clicked()
                }
            }

            Btn {
                label: "Cerrar"
                onClicked: card.closeRequested()
            }
            Btn {
                visible: card.isLink
                label: "Abrir"
                onClicked: card.store.openLink(edit.text.trim())
            }
            Btn {
                visible: card.ready
                primary: true
                label: "Copiar"
                onClicked: card.copy()
            }
        }
    }
}
