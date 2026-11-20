import QtQuick
import QtQuick.Controls
import "../../../../services/tasks/Dates.js" as Dates
import "../../../../services/tasks/Drop.js" as Drop
import "../../../../" as App

// Lista de tareas por secciones. `groups` = [{ key, label, tasks }]. Solo se rehace cuando cambia algo
// de verdad (el reloj recalcula las vistas cada minuto sin tocar las tareas).
ListView {
    id: root

    property var groups: []
    property string selectedId: ""
    property bool showHeaders: true
    property bool showProject: true
    property string emptyText: "Nada por aquí"
    // Filas visibles: [{ kind: "header" | "task", group, id, task, label, extra, late }]
    property var rows: []
    // Item donde vive la fila mientras se arrastra (lo pone el panel)
    property Item dragParent

    // ── Arrastre: la fila flota y las demás se corren para dejarle el hueco ──
    property string dragId: ""
    property Item dragItem: null
    property int dragFrom: -1
    // Fila antes de la cual se abre el hueco, y a qué grupo y posición (sin contar la arrastrada) cae
    property int dragAt: -1
    property string dragGroup: ""
    property int dragIndex: 0
    // Grupos donde no se puede soltar una tarea de otro grupo (Vencidas) y si hay orden manual (hueco)
    property var lockedGroups: []
    property bool manualOrder: true
    property string dragSourceGroup: ""
    // Está sobre un grupo donde no vale soltar
    property bool dragInvalid: false
    readonly property bool dragging: dragId !== ""
    readonly property real rowStep: App.Config.tasks.rowHeight + spacing

    signal taskClicked(string id)
    signal taskToggled(string id)
    signal taskOpened(string id)
    // Se soltó la tarea `id` en el grupo `group`, en la posición `index` (sin contarla a ella)
    signal taskDropped(string id, string group, int index)

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    spacing: 2
    model: rows
    // Mientras se arrastra, las filas que salen de la vista no se destruyen (la arrastrada es una de ellas)
    cacheBuffer: dragging ? 100000 : 400

    ScrollBar.vertical: ScrollBar {
        id: bar
        policy: ScrollBar.AsNeeded
        visible: size < 1
        width: 6
        contentItem: Rectangle {
            implicitWidth: 4
            radius: 2
            color: bar.pressed ? App.Theme.white : App.Theme.gray
            opacity: bar.active || bar.pressed ? 0.9 : 0.4
            Behavior on opacity {
                NumberAnimation {
                    duration: App.Config.anim.hover
                }
            }
        }
        background: Item {}
    }

    onGroupsChanged: rebuild()
    onShowHeadersChanged: rebuild()

    function build() {
        const out = [];
        for (const g of groups) {
            if (showHeaders) {
                let est = 0;
                g.tasks.forEach(t => est += t.estimate);
                out.push({
                    kind: "header",
                    group: g.key,
                    id: "h:" + g.key,
                    label: g.label,
                    extra: g.key === "overdue" ? "" : Dates.formatMinutes(est),
                    late: g.key === "overdue"
                });
            }
            if (g.tasks.length === 0)
                out.push({
                    kind: "empty",
                    group: g.key,
                    id: "e:" + g.key
                });
            for (const t of g.tasks)
                out.push({
                    kind: "task",
                    group: g.key,
                    id: t.id,
                    task: t
                });
        }
        return out;
    }

    function same(a, b) {
        if (a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; i++) {
            const x = a[i];
            const y = b[i];
            if (x.kind !== y.kind || x.group !== y.group || x.id !== y.id || x.task !== y.task || x.label !== y.label || x.extra !== y.extra)
                return false;
        }
        return true;
    }

    function rebuild() {
        const next = build();
        if (!same(next, rows))
            rows = next;
    }

    function indexOfTask(id) {
        return rows.findIndex(r => r.kind === "task" && r.id === id);
    }

    // Mantiene a la vista la tarea elegida
    function ensureVisible(id) {
        const i = indexOfTask(id);
        if (i < 0)
            return;
        // Con una sección arriba de la primera fila, se deja ver el título
        positionViewAtIndex(i === 1 && rows[0].kind === "header" ? 0 : i, ListView.Contain);
    }

    function beginDrag(id, index, card) {
        dragId = id;
        dragFrom = index;
        dragAt = index;
        dragItem = card;
        dragGroup = rows[index].group;
        dragSourceGroup = dragGroup;
        dragInvalid = false;
        dragIndex = 0;
        tick();
    }

    // Esc: la fila suelta sin hacer nada
    function cancelDrag() {
        if (!dragging)
            return false;
        const it = itemAtIndex(dragFrom);
        if (it && it.item)
            it.item.cancelled = true;
        clearDrag();
        return true;
    }

    function clearDrag() {
        dragId = "";
        dragItem = null;
        dragFrom = -1;
        dragAt = -1;
        dragInvalid = false;
    }

    function endDrag(cancelled) {
        const id = dragId;
        const group = dragGroup;
        const index = dragIndex;
        clearDrag();
        if (!cancelled && id !== "" && group !== "")
            taskDropped(id, group, index);
    }

    // Con la fila en el aire: desplaza la lista si está cerca del borde y busca dónde caería
    function tick() {
        if (!dragging || !dragItem)
            return;
        // El puntero (el punto de la fila que se agarró)
        const cx = dragItem.grabX;
        const cy = dragItem.grabY;
        const v = mapFromItem(dragItem, cx, cy);
        let dy = 0;
        if (v.y < 40)
            dy = -(40 - v.y) / 40 * 16;
        else if (v.y > height - 40)
            dy = (v.y - (height - 40)) / 40 * 16;
        if (dy !== 0 && contentHeight > height) {
            contentY = Math.max(originY, Math.min(originY + contentHeight - height, contentY + dy));
            returnToBounds();
        }
        const y = contentItem.mapFromItem(dragItem, cx, cy).y;
        // Grupo bajo la fila: el de la fila donde está (arriba de todo = el primero, abajo de todo = el último)
        let group = rows[rows.length - 1].group;
        for (let i = 0; i < rows.length; i++) {
            const it = itemAtIndex(i);
            if (it && y < it.y + it.height + spacing / 2) {
                group = rows[i].group;
                break;
            }
        }
        // Fuera de la lista (sobre la barra lateral) no hay destino aquí: lo recibe la barra
        if (v.x < 0 || v.x > width)
            group = "";
        dragInvalid = group !== "" && group !== dragSourceGroup && lockedGroups.includes(group);
        if (dragInvalid)
            group = "";
        const others = [];
        let header = -1;
        for (let i = 0; i < rows.length; i++) {
            const r = rows[i];
            if (r.group !== group)
                continue;
            if (r.kind === "header")
                header = i;
            else if (r.kind === "task" && i !== dragFrom)
                others.push(i);
        }
        let n = 0;
        for (const i of others) {
            const it = itemAtIndex(i);
            if (it && y > it.y + it.height / 2)
                n++;
        }
        dragGroup = group;
        dragIndex = n;
        // Sin orden manual la tarea cae donde la deja el orden: no se abre hueco, solo se resalta la sección
        if (!manualOrder || group === "")
            dragAt = dragFrom;
        else
            dragAt = n < others.length ? others[n] : (others.length > 0 ? others[others.length - 1] + 1 : (header >= 0 ? header + 1 : dragFrom));
    }

    Timer {
        running: root.dragging
        repeat: true
        interval: 16
        onTriggered: root.tick()
    }

    delegate: Loader {
        id: cell
        required property var modelData
        required property int index
        width: ListView.view.width
        height: modelData.kind === "task" ? App.Config.tasks.rowHeight : 30
        // Hueco del arrastre: las filas se corren (el título de sección también)
        transform: Translate {
            y: root.dragging ? Drop.gapShift(cell.index, root.dragFrom, root.dragAt, root.rowStep) : 0
            Behavior on y {
                NumberAnimation {
                    duration: App.Config.anim.hover
                    easing.type: Easing.OutCubic
                }
            }
        }
        sourceComponent: modelData.kind === "task" ? rowComponent : (modelData.kind === "empty" ? emptyComponent : headerComponent)

        Component {
            id: rowComponent
            TaskRow {
                task: cell.modelData.task
                selected: root.selectedId === cell.modelData.id
                showProject: root.showProject
                dragParent: root.dragParent
                forbidden: root.dragInvalid
                onDragBegan: card => root.beginDrag(cell.modelData.id, cell.index, card)
                onDragEnded: cancelled => root.endDrag(cancelled)
                onClicked: root.taskClicked(cell.modelData.id)
                onToggled: root.taskToggled(cell.modelData.id)
                onOpened: root.taskOpened(cell.modelData.id)
            }
        }

        Component {
            id: emptyComponent
            Text {
                leftPadding: 10
                verticalAlignment: Text.AlignVCenter
                text: "Sin tareas"
                color: root.dragging && root.dragGroup === cell.modelData.group ? App.Theme.primary : App.Theme.grayDark
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
        }

        Component {
            id: headerComponent
            Item {
                height: 30
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    text: cell.modelData.label.toUpperCase() + (cell.modelData.extra !== "" ? " · " + cell.modelData.extra : "")
                    // Sección de destino mientras se arrastra otra tarea
                    color: cell.modelData.late ? App.Theme.red : (root.dragging && root.dragGroup === cell.modelData.group && root.dragGroup !== root.dragSourceGroup ? App.Theme.primary : App.Theme.gray)
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.6
                }
            }
        }
    }

    Text {
        visible: root.rows.length === 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: 40
        text: root.emptyText
        color: App.Theme.grayDark
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.md
    }
}
