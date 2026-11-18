import QtQuick
import Quickshell.Io
import "../../../../services/tasks/" as TS
import "../../../../services/tasks/Links.js" as Links
import "../../../../" as App

// Quick add (Super+Shift+T): una línea en la isla para crear una tarea desde cualquier lado.
// Debajo salen los chips de lo que entendió (con × si se equivocó) y, si hay un link copiado, la
// sugerencia de usarlo (Tab). Enter guarda y cierra; Esc cierra.
Item {
    id: root

    readonly property var store: TS.TaskStore

    signal closeRequested

    implicitHeight: field.height + (chips.visible ? chips.height + 10 : 0) + (clip.visible ? clip.height + 10 : 0)

    // Link del portapapeles ("" = no hay)
    property string clipUrl: ""
    readonly property string clipLabel: clipUrl !== "" ? Links.linkInfo(clipUrl).label : ""

    // Lo que entendió de lo escrito
    readonly property var parsed: store.parseText(input.text)
    readonly property var chipList: store.chipsFor(parsed)

    // Al abrirse: campo vacío y enfocado, y mira si el portapapeles tiene un link
    function open() {
        input.text = "";
        clipUrl = "";
        input.forceActiveFocus();
        clipProc.running = false;
        clipProc.running = true;
    }

    function acceptClip() {
        if (clipUrl === "")
            return;
        input.text = (input.text.trim() + " " + clipUrl).trim();
        input.cursorPosition = input.text.length;
        clipUrl = "";
    }

    function submit() {
        const id = store.addFromText(input.text, {});
        if (id === "")
            return;
        store.notifyCreated(id);
        root.closeRequested();
    }

    onVisibleChanged: if (visible)
        open()

    // El portapapeles: solo cuenta si es un link suelto
    Process {
        id: clipProc
        command: ["wl-paste", "-n", "-t", "text/plain"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                const u = t.length < 2000 && !/\s/.test(t) && /^(https?|file):\/\//i.test(t) ? Links.normalizeUrl(t) : "";
                root.clipUrl = u;
            }
        }
    }

    Rectangle {
        id: field
        width: parent.width
        height: 48
        radius: 14
        color: App.Theme.surface
        border.width: 1
        border.color: App.Theme.primary

        Text {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(0xf067)
            color: App.Theme.gray
            font.family: App.Config.fonts.icons
            font.pixelSize: App.Config.fontSize.icon
        }
        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 44
            anchors.rightMargin: 16
            verticalAlignment: TextInput.AlignVCenter
            color: App.Theme.white
            selectionColor: App.Theme.primary
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.lg + 1
            clip: true
            onAccepted: root.submit()
            Keys.onTabPressed: event => {
                if (root.clipUrl !== "" && !text.includes(root.clipUrl))
                    root.acceptClip();
                event.accepted = true;
            }
        }
        Text {
            visible: input.text === ""
            anchors.fill: parent
            anchors.leftMargin: 44
            verticalAlignment: Text.AlignVCenter
            text: "Nueva tarea…   mañana 9am +proyecto #etiqueta p1 30m"
            elide: Text.ElideRight
            color: App.Theme.placeholder
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.lg
        }
    }

    ParseChips {
        id: chips
        visible: chipList.length > 0
        y: field.height + 10
        width: parent.width
        chips: root.chipList
        onRemoved: chip => {
            input.text = root.store.removeChip(input.text, chip);
            input.cursorPosition = input.text.length;
            input.forceActiveFocus();
        }
    }

    // 📋 Usar el link copiado
    Rectangle {
        id: clip
        visible: root.clipUrl !== "" && !input.text.includes(root.clipUrl)
        y: field.height + 10 + (chips.visible ? chips.height + 10 : 0)
        width: parent.width
        height: 32
        radius: 10
        color: clipMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface

        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: 12
            width: parent.width - 24
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: String.fromCodePoint(0xf0ea)
                color: App.Theme.gray
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.sm
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 80
                text: "Usar el link copiado: " + root.clipLabel
                elide: Text.ElideRight
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Tab"
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.xs
            }
        }
        MouseArea {
            id: clipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.acceptClip();
                input.forceActiveFocus();
            }
        }
    }
}
