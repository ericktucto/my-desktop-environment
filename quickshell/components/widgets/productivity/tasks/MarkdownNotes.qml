import QtQuick
import "../../../../" as App

// Notas en Markdown: vista previa (con links que se abren) y modo edición. Qt no edita y muestra a la
// vez, así que hay dos modos. Se guarda al salir de la edición (botón, clic fuera o Esc).
Item {
    id: root

    // Texto guardado de la tarea
    property string text: ""

    signal saved(string text)

    property bool editing: false
    readonly property real contentHeight: editing ? Math.max(90, edit.contentHeight + 20) : (text.trim() === "" ? 40 : Math.max(40, preview.implicitHeight + 16))

    implicitHeight: contentHeight

    // Esc: sale de la edición guardando; true si estaba editando
    function back() {
        if (!editing)
            return false;
        finish();
        return true;
    }

    function startEdit() {
        edit.text = root.text;
        editing = true;
        edit.forceActiveFocus();
        edit.cursorPosition = edit.length;
    }

    function finish() {
        if (!editing)
            return;
        editing = false;
        if (edit.text !== root.text)
            root.saved(edit.text);
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: root.editing ? App.Theme.surface : "transparent"
        border.width: root.editing ? 1 : 0
        border.color: App.Theme.primary
    }

    Text {
        id: preview
        visible: !root.editing && root.text.trim() !== ""
        x: 8
        y: 8
        width: parent.width - 16
        text: root.text
        textFormat: Text.MarkdownText
        wrapMode: Text.Wrap
        color: App.Theme.white
        linkColor: App.Theme.primary
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.md
        onLinkActivated: link => Qt.openUrlExternally(link)
    }

    Text {
        visible: !root.editing && root.text.trim() === ""
        x: 8
        y: 8
        text: "Sin notas. Clic para escribir (admite Markdown)"
        color: App.Theme.placeholder
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.md
    }

    // Sin notas: un clic en el aviso empieza a escribir. Con notas, se edita con el botón Editar
    // (así los links de la vista previa reciben sus clics).
    MouseArea {
        anchors.fill: parent
        visible: !root.editing && root.text.trim() === ""
        cursorShape: Qt.IBeamCursor
        onClicked: root.startEdit()
    }

    TextEdit {
        id: edit
        visible: root.editing
        x: 10
        y: 10
        width: parent.width - 20
        wrapMode: TextEdit.Wrap
        color: App.Theme.white
        selectionColor: App.Theme.primary
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.md
        onActiveFocusChanged: if (!activeFocus)
            Qt.callLater(root.finish)
    }
}
