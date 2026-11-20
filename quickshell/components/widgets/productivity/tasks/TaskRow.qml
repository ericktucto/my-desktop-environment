import QtQuick
import "../../../../services/tasks/" as TS
import "../../../../services/tasks/Dates.js" as Dates
import "../../../../" as App

// Una tarea en la lista: el círculo de estado, el título y, debajo, chips chicos con lo que importa
// (fecha, repetición, prioridad, proyecto, etiquetas, subtareas, estimación y links).
Item {
    id: root

    property var task
    property bool selected: false
    property bool showProject: true
    // Item donde vive la tarjeta mientras se arrastra (el panel entero, para poder llegar a la barra)
    property Item dragParent
    // Se canceló el arrastre (Esc): se suelta sin hacer nada
    property bool cancelled: false

    // Clic en la fila (selecciona), en el círculo (completa o reabre) y doble clic (abre el detalle)
    signal clicked
    signal toggled
    signal opened
    // Arrastre: empieza (con la tarjeta que se mueve) y termina (cancelado o no)
    signal dragBegan(Item card)
    signal dragEnded(bool cancelled)

    readonly property var store: TS.TaskStore
    readonly property alias dragging: rowMouse.drag.active
    readonly property bool closed: task.status === "done" || task.status === "cancelled"
    readonly property color priorityColor: task.priority < 4 ? App.Config.tasks.priorityColors[String(task.priority)] : App.Theme.gray
    readonly property color ringColor: closed ? (task.status === "done" ? App.Theme.green : App.Theme.grayDark) : task.status === "blocked" ? App.Theme.red : task.status === "doing" ? App.Theme.primary : priorityColor
    readonly property var chips: buildChips(task, store.now, store.projects, showProject)

    // Chips: { text, color, glyph (opcional), dot (color de un punto, opcional) }
    function buildChips(t, now, projects, withProject) {
        const out = [];
        const gray = App.Theme.gray;
        if (closed && t.completed > 0)
            out.push({
                text: (t.status === "done" ? "hecha " : "cancelada ") + Dates.clock(t.completed),
                color: gray
            });
        if (t.status === "blocked")
            out.push({
                text: "bloqueada" + (t.blockedReason !== "" ? ": " + t.blockedReason : ""),
                color: App.Theme.amber
            });
        if (t.due && !closed) {
            const late = Dates.isOverdue(t, now);
            out.push({
                text: Dates.relative(t.due, t.dueTime, now),
                color: late ? App.Theme.red : (t.due === Dates.todayKey(now) ? App.Theme.white : gray)
            });
        }
        if (t.start && t.start > Dates.todayKey(now) && !closed)
            out.push({
                text: "desde " + Dates.relative(t.start, "", now),
                color: gray
            });
        if (t.repeat)
            out.push({
                glyph: 0xf01e,
                text: "",
                color: gray
            });
        if (t.priority < 4)
            out.push({
                text: "p" + t.priority,
                color: App.Config.tasks.priorityColors[String(t.priority)]
            });
        if (withProject && t.project) {
            const p = projects.find(x => x.id === t.project);
            if (p)
                out.push({
                    text: p.name,
                    color: gray,
                    dot: p.color
                });
        }
        t.tags.forEach(g => out.push({
                text: "#" + g,
                color: gray
            }));
        if (t.subtasks.length > 0)
            out.push({
                text: t.subtasks.filter(s => s.done).length + "/" + t.subtasks.length,
                color: gray
            });
        if (t.estimate > 0)
            out.push({
                text: Dates.formatMinutes(t.estimate),
                color: gray
            });
        // Tiempo trabajado con el Pomodoro
        if (t.focus && t.focus.minutes > 0)
            out.push({
                glyph: 0xf2f2,
                text: Dates.formatMinutes(t.focus.minutes),
                color: gray
            });
        if (t.links.length > 0)
            out.push({
                glyph: 0xf0c1,
                text: String(t.links.length),
                color: gray
            });
        // Estado del primer PR o issue de GitHub: abierto, merged, cerrado o borrador
        const gh = t.links.find(l => l.state !== undefined && l.state !== "");
        if (gh && !closed) {
            const names = {
                "open": "abierto",
                "merged": "merged",
                "closed": "cerrado",
                "draft": "borrador"
            };
            const colors = {
                "open": App.Theme.green,
                "merged": App.Theme.purple,
                "closed": App.Theme.red,
                "draft": gray
            };
            out.push({
                text: names[gh.state] ?? gh.state,
                color: colors[gh.state] ?? gray,
                dot: colors[gh.state] ?? gray
            });
        }
        return out;
    }

    height: App.Config.tasks.rowHeight
    z: dragging ? 100 : 0

    // Esc a mitad del arrastre: la tarjeta vuelve a su sitio sin esperar a soltar el botón
    onCancelledChanged: {
        if (cancelled) {
            card.x = 0;
            card.y = 0;
        }
    }

    // Clic y doble clic en la fila, y el arrastre. Va por debajo de la tarjeta: los botones de adentro
    // (círculo y «›») tienen su propio MouseArea y los demás clics pasan hasta aquí.
    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        drag.target: root.cancelled ? null : card
        drag.threshold: 6
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor
        onPressed: root.cancelled = false
        onClicked: root.clicked()
        onDoubleClicked: root.opened()
        // Al soltar, la tarjeta vuelve a su sitio (la lista se rehace si algo cambió)
        drag.onActiveChanged: {
            if (drag.active) {
                root.dragBegan(card);
            } else {
                root.dragEnded(root.cancelled);
                // (si la lista se rehizo al soltar, la tarjeta ya no existe)
                Qt.callLater(() => {
                    if (card) {
                        card.x = 0;
                        card.y = 0;
                    }
                });
            }
        }
    }

    Rectangle {
        id: card
        width: root.width
        height: root.height
        radius: 10
        color: root.selected ? App.Theme.surfaceActive : (rowMouse.containsMouse || root.dragging ? App.Theme.surface : "transparent")
        border.width: root.dragging ? 1 : 0
        border.color: App.Theme.primary
        opacity: root.dragging ? 0.92 : 1

        // Se saca de la lista mientras se arrastra
        Drag.active: root.dragging
        Drag.keys: ["task"]
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        property string taskId: root.task.id

        states: State {
            when: root.dragging && !root.cancelled && root.dragParent !== null
            ParentChange {
                target: card
                parent: root.dragParent
            }
        }

        // Círculo de estado: vacío = pendiente, punto = en curso, raya = bloqueada, check = hecha
        Item {
            id: dot
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22

            Rectangle {
                anchors.fill: parent
                radius: 11
                color: root.task.status === "done" ? App.Theme.green : (dotMouse.containsMouse && !root.closed ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                border.width: 2
                border.color: root.ringColor
            }
            Rectangle {
                visible: root.task.status === "doing"
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 4
                color: App.Theme.primary
            }
            Rectangle {
                visible: root.task.status === "blocked"
                anchors.centerIn: parent
                width: 10
                height: 2
                radius: 1
                color: App.Theme.red
            }
            Text {
                visible: root.closed
                anchors.centerIn: parent
                text: String.fromCodePoint(root.task.status === "done" ? 0xf00c : 0xf00d)
                color: root.task.status === "done" ? App.Theme.black : App.Theme.grayDark
                font.family: App.Config.fonts.icons
                font.pixelSize: 11
            }
            MouseArea {
                id: dotMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggled()
            }
        }

        // Botón para entrar al detalle
        Rectangle {
            id: detailButton
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            radius: 14
            color: detailMouse.containsMouse ? App.Theme.surfaceActive : "transparent"
            Text {
                anchors.centerIn: parent
                text: String.fromCodePoint(0xf105)
                color: detailMouse.containsMouse || root.selected ? App.Theme.white : App.Theme.gray
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.icon
            }
            MouseArea {
                id: detailMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.opened()
            }
        }

        Column {
            anchors.left: dot.right
            anchors.leftMargin: 12
            anchors.right: grip.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: root.task.title
                elide: Text.ElideRight
                color: root.closed ? App.Theme.gray : App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
                font.weight: Font.Medium
                font.strikeout: root.closed
            }

            Row {
                visible: root.chips.length > 0
                width: parent.width
                height: 14
                spacing: 10
                clip: true

                Repeater {
                    model: root.chips
                    Row {
                        id: chip
                        required property var modelData
                        spacing: 4
                        height: 14

                        Rectangle {
                            visible: chip.modelData.dot !== undefined
                            anchors.verticalCenter: parent.verticalCenter
                            width: 7
                            height: 7
                            radius: 3.5
                            color: chip.modelData.dot ?? "transparent"
                        }
                        Text {
                            visible: chip.modelData.glyph !== undefined
                            anchors.verticalCenter: parent.verticalCenter
                            text: String.fromCodePoint(chip.modelData.glyph ?? 0x20)
                            color: chip.modelData.color
                            font.family: App.Config.fonts.icons
                            font.pixelSize: App.Config.fontSize.xs
                        }
                        Text {
                            visible: chip.modelData.text !== ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: chip.modelData.text
                            color: chip.modelData.color
                            font.family: App.Config.fonts.text
                            font.pixelSize: App.Config.fontSize.xs
                        }
                    }
                }
            }
        }

        // Pista de que se puede arrastrar
        Text {
            id: grip
            anchors.right: detailButton.left
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            horizontalAlignment: Text.AlignHCenter
            text: "\u283F"
            color: App.Theme.gray
            opacity: rowMouse.containsMouse || root.dragging ? 0.7 : 0
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
        }
    }
}
