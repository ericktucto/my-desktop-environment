import QtQuick
import "../../../../services/tasks/" as TS
import "../../../../services/timer/" as TM
import "../../../../services/tasks/Dates.js" as Dates
import "../../../../services/tasks/Reminders.js" as Reminders
import "../../../../services/tasks/Parse.js" as Parse
import "../../../../" as App

// Detalle de una tarea (reemplaza a la lista): título, estado, prioridad, proyecto, etiquetas, fechas,
// estimación, subtareas, notas en Markdown y links. Cada campo se guarda al terminar de editarlo
// (Enter o al salir del campo), así el deshacer deshace un campo entero y no cada letra.
Item {
    id: root

    property string taskId: ""

    readonly property var store: TS.TaskStore
    // Tiempo trabajado con el temporizador
    readonly property var focusInfo: t.focus ?? ({
            minutes: 0,
            pomodoros: 0
        })
    readonly property var blank: ({
            id: "",
            title: "",
            notes: "",
            status: "todo",
            blockedReason: "",
            priority: 4,
            project: null,
            tags: [],
            due: "",
            dueTime: "",
            start: "",
            estimate: 0,
            subtasks: [],
            links: [],
            created: 0,
            completed: 0
        })
    readonly property var found: store.get(taskId)
    readonly property var t: found ?? blank
    readonly property bool cancelled: t.status === "cancelled"

    // Volver a la lista (‹, Esc o la tarea ya no existe)
    signal closeRequested
    // Eliminar desde el menú ⋮ (el panel pregunta si la tarea se repite)
    signal deleteRequested(string id)

    onFoundChanged: {
        if (found === null)
            closeRequested();
        else
            sync();
    }
    onTaskIdChanged: {
        templateSaved = "";
        sync();
        store.refreshStale([taskId]);
    }
    Component.onCompleted: {
        sync();
        store.refreshStale([taskId]);
    }

    // Pone en los campos lo guardado, salvo el que se está escribiendo
    function sync() {
        if (!t)
            return;
        if (!titleInput.editor.activeFocus)
            titleInput.text = t.title;
        if (!timeInput.editor.activeFocus)
            timeInput.text = t.dueTime;
        if (!estimateInput.editor.activeFocus)
            estimateInput.text = t.estimate > 0 ? Dates.formatMinutes(t.estimate).replace(/ /g, "") : "";
        if (!reasonInput.editor.activeFocus)
            reasonInput.text = t.blockedReason;
    }

    function patch(changes) {
        store.update(taskId, changes);
    }

    // Esc: cierra lo que esté abierto; true si había algo
    function back() {
        if (picker.visible || projectMenu.visible || moreMenu.visible || remindMenu.visible || repeatPicker.visible) {
            closePopups();
            return true;
        }
        if (notes.back() || subtasks.back())
            return true;
        const focused = titleInput.editor.activeFocus || timeInput.editor.activeFocus || estimateInput.editor.activeFocus || reasonInput.editor.activeFocus || tagInput.editor.activeFocus || linkInput.editor.activeFocus;
        if (focused) {
            root.forceActiveFocus();
            sync();
            return true;
        }
        return false;
    }

    function reset() {
        closePopups();
        notes.finish();
    }

    function closePopups() {
        picker.visible = false;
        projectMenu.visible = false;
        moreMenu.visible = false;
        remindMenu.visible = false;
        repeatPicker.visible = false;
    }

    // ── Fechas ──
    property string pickerFor: ""

    function openPicker(which, anchor) {
        closePopups();
        pickerFor = which;
        picker.value = which === "due" ? t.due : t.start;
        picker.todayKey = store.todayKey;
        picker.open();
        const p = anchor.mapToItem(root, 0, anchor.height + 6);
        picker.x = Math.max(0, Math.min(p.x, root.width - picker.width));
        picker.y = Math.max(0, Math.min(p.y, root.height - picker.height));
        picker.visible = true;
    }

    function commitTime() {
        const text = timeInput.text.trim();
        const v = text === "" ? "" : Dates.normTime(text);
        if (text !== "" && v === "") {
            sync();
            return;
        }
        if (v !== t.dueTime)
            patch({
                dueTime: v
            });
        timeInput.text = v;
    }

    function commitEstimate() {
        const m = Dates.parseMinutes(estimateInput.text);
        if (m < 0) {
            sync();
            return;
        }
        if (m !== t.estimate)
            patch({
                estimate: m
            });
    }

    function commitTitle() {
        const s = titleInput.text.trim();
        if (s === "") {
            sync();
            return;
        }
        if (s !== t.title)
            patch({
                title: s
            });
    }

    function addTags(text) {
        const list = text.split(/[\s,]+/).map(x => x.replace(/^#+/, "").toLowerCase()).filter(x => x !== "");
        if (list.length > 0)
            patch({
                tags: t.tags.concat(list)
            });
    }

    property bool linkError: false
    // Nombre de la plantilla recién guardada (para el aviso del botón)
    property string templateSaved: ""

    function addLink() {
        const text = linkInput.text.trim();
        if (text === "")
            return;
        if (store.addLink(taskId, text)) {
            linkInput.text = "";
            linkError = false;
        } else {
            linkError = true;
            linkErrorTimer.restart();
        }
    }

    Timer {
        id: linkErrorTimer
        interval: 2500
        onTriggered: root.linkError = false
    }

    // ── Piezas ──
    component Pill: Rectangle {
        id: pill
        property string label: ""
        property bool selected: false
        property color accent: App.Theme.primary
        property bool dropdown: false
        property color dot: "transparent"

        signal clicked

        implicitWidth: pillRow.implicitWidth + 24
        height: 28
        radius: 14
        color: selected ? accent : (pillMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface)

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 6
            Rectangle {
                visible: pill.dot.a > 0
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: pill.dot
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.label
                color: pill.selected ? App.Theme.onColor(pill.accent) : App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
                font.weight: Font.DemiBold
            }
            Text {
                visible: pill.dropdown
                anchors.verticalCenter: parent.verticalCenter
                text: String.fromCodePoint(0xf0d7)
                color: App.Theme.gray
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.xs
            }
        }
        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }

    component FieldInput: Rectangle {
        id: field
        property alias text: input.text
        property alias editor: input
        property string placeholder: ""
        property int fontSize: App.Config.fontSize.md
        property bool bold: false

        signal committed
        signal accepted

        height: 30
        radius: 10
        color: App.Theme.surface
        border.width: 1
        border.color: input.activeFocus ? App.Theme.primary : "transparent"

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            color: App.Theme.white
            selectionColor: App.Theme.primary
            font.family: App.Config.fonts.text
            font.pixelSize: field.fontSize
            font.weight: field.bold ? Font.DemiBold : Font.Normal
            clip: true
            onAccepted: {
                field.committed();
                field.accepted();
            }
            onActiveFocusChanged: if (!activeFocus)
                field.committed()
        }
        Text {
            visible: input.text === "" && !input.activeFocus
            anchors.fill: parent
            anchors.leftMargin: 10
            verticalAlignment: Text.AlignVCenter
            text: field.placeholder
            elide: Text.ElideRight
            color: App.Theme.placeholder
            font.family: App.Config.fonts.text
            font.pixelSize: field.fontSize
        }
    }

    component Caption: Text {
        color: App.Theme.grayDark
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
    }

    // ── Cabecera ──
    Item {
        id: head
        width: parent.width
        height: 36

        TaskIconButton {
            id: backButton
            anchors.verticalCenter: parent.verticalCenter
            glyph: 0xf104
            onClicked: root.closeRequested()
        }
        FieldInput {
            id: titleInput
            anchors.left: backButton.right
            anchors.leftMargin: 8
            anchors.right: moreButton.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 34
            fontSize: App.Config.fontSize.lg + 2
            bold: true
            placeholder: "Título"
            onCommitted: root.commitTitle()
            onAccepted: root.forceActiveFocus()
        }
        TaskIconButton {
            id: moreButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            glyph: 0xf142
            active: moreMenu.visible
            onClicked: {
                const open = !moreMenu.visible;
                root.closePopups();
                moreMenu.visible = open;
            }
        }
    }

    Flickable {
        id: flick
        y: head.height + 10
        width: parent.width
        height: parent.height - y
        contentWidth: width
        contentHeight: column.implicitHeight + 8
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column
            width: flick.width - 6
            spacing: 14

            // Estado y prioridad
            Flow {
                width: parent.width
                spacing: 16

                Row {
                    spacing: 4
                    Repeater {
                        model: [
                            {
                                id: "todo",
                                label: "Pendiente"
                            },
                            {
                                id: "doing",
                                label: "En curso"
                            },
                            {
                                id: "blocked",
                                label: "Bloqueada"
                            },
                            {
                                id: "done",
                                label: "Hecha"
                            }
                        ]
                        Pill {
                            required property var modelData
                            label: modelData.label
                            selected: root.t.status === modelData.id
                            onClicked: root.store.setStatus(root.taskId, modelData.id, modelData.id === "blocked" ? reasonInput.text : "")
                        }
                    }
                    Pill {
                        visible: root.cancelled
                        label: "Cancelada"
                        selected: true
                        accent: App.Theme.grayDark
                    }
                }
                Row {
                    spacing: 4
                    Repeater {
                        model: [1, 2, 3, 4]
                        Pill {
                            required property int modelData
                            label: "P" + modelData
                            selected: root.t.priority === modelData
                            accent: modelData < 4 ? App.Config.tasks.priorityColors[String(modelData)] : App.Theme.grayDark
                            onClicked: root.patch({
                                priority: modelData
                            })
                        }
                    }
                }
            }

            FieldInput {
                id: reasonInput
                visible: root.t.status === "blocked"
                width: parent.width
                placeholder: "¿Qué la bloquea? (motivo)"
                onCommitted: if (root.t.status === "blocked")
                    root.store.setStatus(root.taskId, "blocked", text.trim())
                onAccepted: root.forceActiveFocus()
            }

            // Proyecto y etiquetas
            Flow {
                width: parent.width
                spacing: 6

                Caption {
                    height: 28
                    verticalAlignment: Text.AlignVCenter
                    rightPadding: 4
                    text: "PROYECTO"
                }
                Pill {
                    id: projectPill
                    readonly property var project: root.store.project(root.t.project)
                    label: project ? project.name : "Bandeja"
                    dot: project ? project.color : "transparent"
                    dropdown: true
                    onClicked: {
                        const open = !projectMenu.visible;
                        root.closePopups();
                        if (open) {
                            const p = projectPill.mapToItem(root, 0, projectPill.height + 6);
                            projectMenu.x = p.x;
                            projectMenu.y = p.y;
                            projectMenu.visible = true;
                        }
                    }
                }
                Item {
                    width: 10
                    height: 1
                }
                Caption {
                    height: 28
                    verticalAlignment: Text.AlignVCenter
                    rightPadding: 4
                    text: "ETIQUETAS"
                }
                Repeater {
                    model: root.t.tags
                    Rectangle {
                        id: tag
                        required property string modelData
                        width: tagText.implicitWidth + 36
                        height: 28
                        radius: 14
                        color: App.Theme.surface
                        Text {
                            id: tagText
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "#" + tag.modelData
                            color: App.Theme.white
                            font.family: App.Config.fonts.text
                            font.pixelSize: App.Config.fontSize.sm
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: String.fromCodePoint(0xf00d)
                            color: tagRemove.containsMouse ? App.Theme.red : App.Theme.gray
                            font.family: App.Config.fonts.icons
                            font.pixelSize: App.Config.fontSize.xs
                            MouseArea {
                                id: tagRemove
                                anchors.fill: parent
                                anchors.margins: -5
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.patch({
                                    tags: root.t.tags.filter(g => g !== tag.modelData)
                                })
                            }
                        }
                    }
                }
                FieldInput {
                    id: tagInput
                    width: 130
                    height: 28
                    radius: 14
                    fontSize: App.Config.fontSize.sm
                    placeholder: "+ etiqueta"
                    onAccepted: {
                        root.addTags(text);
                        text = "";
                    }
                }
            }

            // Sugerencias de etiquetas mientras escribes
            Flow {
                id: suggestions
                readonly property string typed: tagInput.text.trim().replace(/^#+/, "").toLowerCase()
                visible: typed !== "" && list.length > 0
                width: parent.width
                spacing: 6
                readonly property var list: typed === "" ? [] : root.store.tagNames.filter(g => g.startsWith(typed) && !root.t.tags.includes(g)).slice(0, 6)

                Repeater {
                    model: suggestions.list
                    Pill {
                        required property string modelData
                        label: "#" + modelData
                        onClicked: {
                            root.addTags(modelData);
                            tagInput.text = "";
                        }
                    }
                }
            }

            // Fechas y estimación
            Flow {
                width: parent.width
                spacing: 8

                Caption {
                    height: 28
                    verticalAlignment: Text.AlignVCenter
                    text: "VENCE"
                }
                Pill {
                    id: duePill
                    label: root.t.due !== "" ? Dates.shortDate(root.t.due, root.store.now) : "Sin fecha"
                    selected: root.t.due !== "" && Dates.isOverdue(root.t, root.store.now)
                    accent: App.Theme.red
                    dropdown: true
                    onClicked: root.openPicker("due", duePill)
                }
                FieldInput {
                    id: timeInput
                    width: 78
                    height: 28
                    radius: 14
                    opacity: root.t.due !== "" ? 1 : 0.4
                    enabled: root.t.due !== ""
                    fontSize: App.Config.fontSize.sm
                    placeholder: "hora"
                    onCommitted: root.commitTime()
                    onAccepted: root.forceActiveFocus()
                }
                Item {
                    width: 8
                    height: 1
                }
                Caption {
                    height: 28
                    verticalAlignment: Text.AlignVCenter
                    text: "INICIO"
                }
                Pill {
                    id: startPill
                    label: root.t.start !== "" ? Dates.shortDate(root.t.start, root.store.now) : "—"
                    dropdown: true
                    onClicked: root.openPicker("start", startPill)
                }
                Item {
                    width: 8
                    height: 1
                }
                Caption {
                    height: 28
                    verticalAlignment: Text.AlignVCenter
                    text: "ESTIMA"
                }
                FieldInput {
                    id: estimateInput
                    width: 78
                    height: 28
                    radius: 14
                    fontSize: App.Config.fontSize.sm
                    placeholder: "30m, 2h"
                    onCommitted: root.commitEstimate()
                    onAccepted: root.forceActiveFocus()
                }
            }

            // Foco: lo trabajado con el Pomodoro y un atajo para empezar uno con esta tarea
            Flow {
                width: parent.width
                spacing: 6

                Caption {
                    height: 28
                    verticalAlignment: Text.AlignVCenter
                    text: "FOCO"
                }
                Text {
                    height: 28
                    verticalAlignment: Text.AlignVCenter
                    visible: root.focusInfo.minutes > 0 || root.focusInfo.pomodoros > 0
                    text: Dates.formatMinutes(root.focusInfo.minutes) + (root.focusInfo.pomodoros > 0 ? " · " + root.focusInfo.pomodoros + " 🍅" : "")
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                    font.weight: Font.Medium
                }
                Pill {
                    label: "🍅 Pomodoro"
                    selected: TM.TimerStore.pomodoro !== null && TM.TimerStore.pomodoro.pomo.task === root.taskId
                    onClicked: {
                        TM.TimerStore.startPomodoro(root.taskId);
                        TM.TimerStore.openRequested("timer");
                    }
                }
            }

            // Repetición
            Flow {
                width: parent.width
                spacing: 6

                Caption {
                    height: 28
                    verticalAlignment: Text.AlignVCenter
                    rightPadding: 4
                    text: "REPETIR"
                }
                Pill {
                    id: repeatPill
                    label: root.t.repeat ? Parse.repeatLabel(root.t.repeat) : "No se repite"
                    selected: false
                    dropdown: true
                    onClicked: {
                        const open = !repeatPicker.visible;
                        root.closePopups();
                        if (open) {
                            const p = repeatPill.mapToItem(root, 0, repeatPill.height + 6);
                            repeatPicker.x = Math.max(0, Math.min(p.x, root.width - repeatPicker.width));
                            repeatPicker.y = Math.min(p.y, Math.max(0, root.height - repeatPicker.height));
                            repeatPicker.visible = true;
                        }
                    }
                }
            }

            // Recordatorios
            Flow {
                width: parent.width
                spacing: 6

                Caption {
                    height: 28
                    verticalAlignment: Text.AlignVCenter
                    rightPadding: 4
                    text: "AVISAR"
                }
                Repeater {
                    model: root.t.reminders
                    Rectangle {
                        id: remChip
                        required property var modelData
                        width: remText.implicitWidth + 36
                        height: 28
                        radius: 14
                        color: App.Theme.surface
                        Text {
                            id: remText
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: String.fromCodePoint(0xf0f3) + "  " + Reminders.label(remChip.modelData, root.store.now)
                            color: remChip.modelData.firedAt > 0 ? App.Theme.gray : App.Theme.white
                            font.family: App.Config.fonts.text
                            font.pixelSize: App.Config.fontSize.sm
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: String.fromCodePoint(0xf00d)
                            color: remRemove.containsMouse ? App.Theme.red : App.Theme.gray
                            font.family: App.Config.fonts.icons
                            font.pixelSize: App.Config.fontSize.xs
                            MouseArea {
                                id: remRemove
                                anchors.fill: parent
                                anchors.margins: -5
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.patch({
                                    reminders: root.t.reminders.filter(r => r.id !== remChip.modelData.id)
                                })
                            }
                        }
                    }
                }
                Pill {
                    id: remindPill
                    visible: root.t.dueTime !== ""
                    label: "+ aviso"
                    onClicked: {
                        const open = !remindMenu.visible;
                        root.closePopups();
                        if (open) {
                            const p = remindPill.mapToItem(root, 0, remindPill.height + 6);
                            remindMenu.x = Math.min(p.x, root.width - remindMenu.width);
                            remindMenu.y = p.y;
                            remindMenu.visible = true;
                        }
                    }
                }
                Text {
                    visible: root.t.dueTime === "" && root.t.reminders.length === 0
                    height: 28
                    verticalAlignment: Text.AlignVCenter
                    text: "Pon una hora para que avise"
                    color: App.Theme.grayDark
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                }
            }

            Text {
                visible: root.t.start !== "" && root.t.due !== "" && root.t.start > root.t.due
                width: parent.width
                text: "El inicio es posterior a la fecha límite"
                color: App.Theme.amber
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }

            // Subtareas
            Column {
                width: parent.width
                spacing: 6
                Caption {
                    text: "SUBTAREAS" + (root.t.subtasks.length > 0 ? "  " + subtasks.doneCount + "/" + root.t.subtasks.length : "")
                }
                SubtaskList {
                    id: subtasks
                    width: parent.width
                    taskId: root.taskId
                    subtasks: root.t.subtasks
                }
            }

            // Notas
            Column {
                width: parent.width
                spacing: 6
                Item {
                    width: parent.width
                    height: 24
                    Caption {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "NOTAS  (MARKDOWN)"
                    }
                    Pill {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 24
                        label: notes.editing ? "Listo" : "Editar"
                        onClicked: notes.editing ? notes.finish() : notes.startEdit()
                    }
                }
                MarkdownNotes {
                    id: notes
                    width: parent.width
                    text: root.t.notes
                    onSaved: text => root.patch({
                        notes: text
                    })
                }
            }

            // Links
            Column {
                width: parent.width
                spacing: 6
                Caption {
                    text: "LINKS"
                }
                Flow {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: root.t.links
                        LinkChip {
                            required property var modelData
                            required property int index
                            link: modelData
                            onRemoved: root.store.removeLink(root.taskId, index)
                        }
                    }
                    FieldInput {
                        id: linkInput
                        width: 230
                        height: 28
                        radius: 14
                        fontSize: App.Config.fontSize.sm
                        placeholder: "+ URL (PR, issue, Figma, doc…)"
                        border.color: root.linkError ? App.Theme.red : (linkInput.editor.activeFocus ? App.Theme.primary : "transparent")
                        onAccepted: root.addLink()
                    }
                }
                Text {
                    visible: root.linkError
                    text: "Eso no parece un link"
                    color: App.Theme.red
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                }
            }

            // Pie
            Row {
                spacing: 8
                Pill {
                    height: 26
                    label: templateSaved !== "" ? "Plantilla /" + templateSaved + " guardada" : "Guardar como plantilla"
                    onClicked: root.templateSaved = root.store.saveTemplate(root.taskId)
                }
            }
            Text {
                topPadding: 4
                width: parent.width
                text: "Creada " + Dates.ago(root.t.created, root.store.now) + (root.t.completed > 0 ? " · " + (root.cancelled ? "Cancelada " : "Completada ") + Dates.ago(root.t.completed, root.store.now) : "")
                color: App.Theme.grayDark
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.xs
            }
        }
    }

    // ── Ventanas emergentes ──
    MouseArea {
        anchors.fill: parent
        z: 40
        visible: picker.visible || projectMenu.visible || moreMenu.visible || remindMenu.visible || repeatPicker.visible
        onClicked: root.closePopups()
    }

    MiniMonth {
        id: picker
        z: 50
        visible: false
        allowClear: root.pickerFor === "due" || root.pickerFor === "start"
        onPicked: key => {
            if (root.pickerFor === "due")
                root.patch({
                    due: key
                });
            else
                root.patch({
                    start: key
                });
            visible = false;
        }
    }

    Rectangle {
        id: projectMenu
        z: 50
        visible: false
        width: 220
        height: projectColumn.implicitHeight + 12
        radius: 14
        color: App.Theme.island
        border.color: App.Theme.border
        border.width: 1

        Column {
            id: projectColumn
            x: 6
            y: 6
            width: parent.width - 12
            spacing: 2

            Repeater {
                model: [
                    {
                        id: "",
                        name: "Bandeja",
                        color: "transparent"
                    }
                ].concat(root.store.activeProjects)
                Rectangle {
                    id: option
                    required property var modelData
                    width: projectColumn.width
                    height: 30
                    radius: 8
                    color: optionMouse.containsMouse ? App.Theme.surfaceActive : "transparent"
                    Rectangle {
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: option.modelData.color
                    }
                    Text {
                        x: 24
                        anchors.verticalCenter: parent.verticalCenter
                        text: option.modelData.name
                        color: App.Theme.white
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.sm
                    }
                    Text {
                        visible: (root.t.project ?? "") === option.modelData.id
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(0xf00c)
                        color: App.Theme.primary
                        font.family: App.Config.fonts.icons
                        font.pixelSize: App.Config.fontSize.sm
                    }
                    MouseArea {
                        id: optionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.patch({
                                project: option.modelData.id === "" ? null : option.modelData.id
                            });
                            projectMenu.visible = false;
                        }
                    }
                }
            }
        }
    }

    RepeatPicker {
        id: repeatPicker
        z: 50
        visible: false
        repeat: root.t.repeat
        onChanged: r => {
            // Para repetirse, la tarea necesita una fecha: sin ella, hoy
            const changes = {
                repeat: r
            };
            if (r !== null && root.t.due === "")
                changes.due = root.store.todayKey;
            root.patch(changes);
        }
    }

    Rectangle {
        id: remindMenu
        z: 50
        visible: false
        width: 190
        height: remindColumn.implicitHeight + 12
        radius: 14
        color: App.Theme.island
        border.color: App.Theme.border
        border.width: 1

        Column {
            id: remindColumn
            x: 6
            y: 6
            width: parent.width - 12
            spacing: 2

            Repeater {
                model: Reminders.PRESETS.filter(o => !root.t.reminders.some(r => !r.at && r.offset === o))
                Rectangle {
                    id: preset
                    required property int modelData
                    width: remindColumn.width
                    height: 30
                    radius: 8
                    color: presetMouse.containsMouse ? App.Theme.surfaceActive : "transparent"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        text: Reminders.label({
                            offset: preset.modelData,
                            at: ""
                        }, root.store.now)
                        color: App.Theme.white
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.sm
                    }
                    MouseArea {
                        id: presetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            remindMenu.visible = false;
                            root.patch({
                                reminders: root.t.reminders.concat([Reminders.make(preset.modelData)])
                            });
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: moreMenu
        z: 50
        visible: false
        anchors.right: parent.right
        y: head.height + 4
        width: 200
        height: moreColumn.implicitHeight + 12
        radius: 14
        color: App.Theme.island
        border.color: App.Theme.border
        border.width: 1

        Column {
            id: moreColumn
            x: 6
            y: 6
            width: parent.width - 12
            spacing: 2

            Repeater {
                model: [
                    {
                        id: "cancel",
                        label: root.cancelled ? "Reabrir tarea" : "Cancelar tarea",
                        danger: false
                    },
                    {
                        id: "delete",
                        label: "Eliminar tarea",
                        danger: true
                    }
                ]
                Rectangle {
                    id: action
                    required property var modelData
                    width: moreColumn.width
                    height: 30
                    radius: 8
                    color: actionMouse.containsMouse ? App.Theme.surfaceActive : "transparent"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        text: action.modelData.label
                        color: action.modelData.danger ? App.Theme.red : App.Theme.white
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.sm
                    }
                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            moreMenu.visible = false;
                            if (action.modelData.id === "delete")
                                root.deleteRequested(root.taskId);
                            else
                                root.store.setStatus(root.taskId, root.cancelled ? "todo" : "cancelled", "");
                        }
                    }
                }
            }
        }
    }
}
