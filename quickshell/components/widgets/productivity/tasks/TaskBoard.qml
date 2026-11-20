import QtQuick
import QtQuick.Controls
import "../../../../services/tasks/" as TS
import "../../../../" as App

// Tablero: una columna por estado (Pendiente · En curso · Bloqueada · Hecha hoy). Se arrastra una
// tarjeta a otra columna para cambiarle el estado (a Bloqueada, el panel pregunta el motivo), dentro
// de su columna para ordenarla (con orden manual) o a la barra lateral. Arriba, un filtro por proyecto.
Item {
    id: root

    // Grupos de TaskStore.list("board"): [{ key: todo|doing|blocked|done, tasks }] (los vacíos pueden faltar)
    property var groups: []
    property string selectedId: ""
    // Proyecto elegido en el filtro ("" = todos)
    property string project: ""
    property string emptyText: "Sin tareas"
    // Item donde vive la tarjeta mientras se arrastra (el panel entero, para llegar a la barra)
    property Item dragParent
    // Con orden manual se abre el hueco; con otro orden la tarjeta solo cambia de columna
    property bool manualOrder: true

    // ── Arrastre: las tarjetas se corren para dejarle el hueco ──
    property string dragId: ""
    property Item dragItem: null
    property int dragSrcCol: -1
    property int dragSrcIdx: -1
    // Columna bajo el puntero (-1 = fuera del tablero, sobre la barra) y lugar en ella
    property int dragCol: -1
    property int dragIndex: 0
    // Posición (en las tarjetas de esa columna) antes de la cual se abre el hueco
    property int dragAt: -1
    property real dragH: 0
    readonly property bool dragging: dragId !== ""

    signal taskClicked(string id)
    signal taskOpened(string id)
    // Se soltó la tarjeta `id` en la columna `status`, en la posición `index` (sin contarla a ella)
    signal taskDropped(string id, string status, int index)
    signal projectPicked(string id)

    readonly property var store: TS.TaskStore
    readonly property var columns: [
        {
            key: "todo",
            label: "PENDIENTE"
        },
        {
            key: "doing",
            label: "EN CURSO"
        },
        {
            key: "blocked",
            label: "BLOQUEADA"
        },
        {
            key: "done",
            label: "HECHA HOY"
        }
    ]

    function tasksOf(key) {
        return groups.find(g => g.key === key)?.tasks ?? [];
    }

    function beginDrag(id, col, idx, card) {
        dragId = id;
        dragItem = card;
        dragSrcCol = col;
        dragSrcIdx = idx;
        dragCol = col;
        dragIndex = idx;
        dragAt = idx;
        dragH = card.height + 6;
        tick();
    }

    function clearDrag() {
        dragId = "";
        dragItem = null;
        dragSrcCol = -1;
        dragCol = -1;
        dragAt = -1;
    }

    // Esc: la tarjeta vuelve a su sitio sin hacer nada
    function cancelDrag() {
        if (!dragging)
            return false;
        const view = lists.itemAt(dragSrcCol)?.view;
        const it = view?.itemAtIndex(dragSrcIdx);
        if (it)
            it.cancelled = true;
        clearDrag();
        return true;
    }

    function endDrag(cancelled) {
        const id = dragId;
        const col = dragCol;
        const index = dragIndex;
        clearDrag();
        if (!cancelled && id !== "" && col >= 0)
            taskDropped(id, columns[col].key, index);
    }

    // Cuánto se corre la tarjeta `idx` de la columna `col` para dejar el hueco
    function shiftOf(col, idx) {
        if (!dragging || !manualOrder || dragCol < 0)
            return 0;
        let s = 0;
        if (col === dragSrcCol && idx > dragSrcIdx)
            s -= dragH;
        if (col === dragCol && dragAt >= 0 && idx >= dragAt)
            s += dragH;
        return s;
    }

    // Con la tarjeta en el aire: busca la columna y el lugar donde caería (y desplaza la columna si está
    // cerca del borde)
    function tick() {
        if (!dragging || !dragItem)
            return;
        // El puntero (el punto de la tarjeta que se agarró)
        const p = board.mapFromItem(dragItem, dragItem.grabX, dragItem.grabY);
        const colW = (board.width - 3 * board.spacing) / 4;
        if (p.x < 0 || p.x > board.width) {
            dragCol = -1;
            dragAt = -1;
            return;
        }
        const col = Math.max(0, Math.min(3, Math.floor(p.x / (colW + board.spacing))));
        const view = lists.itemAt(col)?.view;
        if (!view)
            return;
        const v = view.mapFromItem(dragItem, dragItem.grabX, dragItem.grabY);
        let dy = 0;
        if (v.y < 40)
            dy = -(40 - v.y) / 40 * 16;
        else if (v.y > view.height - 40)
            dy = (v.y - (view.height - 40)) / 40 * 16;
        if (dy !== 0 && view.contentHeight > view.height) {
            view.contentY = Math.max(view.originY, Math.min(view.originY + view.contentHeight - view.height, view.contentY + dy));
            view.returnToBounds();
        }
        const y = view.contentItem.mapFromItem(dragItem, dragItem.grabX, dragItem.grabY).y;
        const count = tasksOf(columns[col].key).length;
        let n = 0;
        let at = count;
        for (let i = 0; i < count; i++) {
            if (col === dragSrcCol && i === dragSrcIdx)
                continue;
            const it = view.itemAtIndex(i);
            if (!it)
                continue;
            if (y > it.y + it.height / 2)
                n++;
            else if (at === count)
                at = i;
        }
        dragCol = col;
        dragIndex = n;
        // «Hecha hoy» va por hora de cierre: no hay lugar que elegir
        dragAt = columns[col].key === "done" ? -1 : at;
    }

    Timer {
        running: root.dragging
        repeat: true
        interval: 16
        onTriggered: root.tick()
    }

    // Mantiene a la vista la tarjeta elegida
    function ensureVisible(id) {
        for (let c = 0; c < columns.length; c++) {
            const i = tasksOf(columns[c].key).findIndex(t => t.id === id);
            if (i >= 0) {
                lists.itemAt(c)?.positionViewAtIndex(i, ListView.Contain);
                return;
            }
        }
    }

    // Filtro por proyecto
    Flow {
        id: filter
        width: parent.width
        spacing: 4

        Repeater {
            model: [
                {
                    id: "",
                    name: "Todos",
                    color: "transparent"
                }
            ].concat(root.store.activeProjects)
            Rectangle {
                id: pill
                required property var modelData
                width: pillRow.implicitWidth + 20
                height: 26
                radius: 13
                color: root.project === modelData.id ? App.Theme.primary : (pillMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface)
                Row {
                    id: pillRow
                    anchors.centerIn: parent
                    spacing: 5
                    Rectangle {
                        visible: pill.modelData.id !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7
                        height: 7
                        radius: 3.5
                        color: pill.modelData.color
                    }
                    Text {
                        text: pill.modelData.name
                        color: App.Theme.white
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.xs
                        font.weight: Font.DemiBold
                    }
                }
                MouseArea {
                    id: pillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.projectPicked(pill.modelData.id)
                }
            }
        }
    }

    Row {
        id: board
        y: filter.height + 8
        width: parent.width
        height: parent.height - y
        spacing: 8

        Repeater {
            id: lists
            model: root.columns
            // itemAt devuelve el ListView de la columna (ver ensureVisible)
            delegate: Item {
                id: column
                required property var modelData
                required property int index
                width: (board.width - 3 * board.spacing) / 4
                height: board.height
                readonly property alias view: list
                // Las columnas se buscan por su ListView
                function positionViewAtIndex(i, mode) {
                    list.positionViewAtIndex(i, mode);
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.width: root.dragging && root.dragCol === column.index && column.index !== root.dragSrcCol ? 2 : 0
                    border.color: App.Theme.primary
                }

                Text {
                    id: title
                    x: 10
                    y: 8
                    text: column.modelData.label + "  " + root.tasksOf(column.modelData.key).length
                    color: column.modelData.key === "blocked" ? App.Theme.amber : App.Theme.gray
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.6
                }

                ListView {
                    id: list
                    x: 6
                    y: 30
                    width: parent.width - 12
                    height: parent.height - 36
                    clip: true
                    spacing: 6
                    model: root.tasksOf(column.modelData.key)
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    // Un poco de aire al final para que la última tarjeta no quede pegada
                    footer: Item {
                        width: 1
                        height: 6
                    }
                    // Rueda del mouse y barra: la columna se desplaza sola cuando hay más tarjetas que alto
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
                    // Mientras se arrastra, las tarjetas que salen de la vista no se destruyen (la arrastrada es una)
                    cacheBuffer: root.dragging ? 100000 : 320
                    delegate: TaskCard {
                        id: card
                        required property var modelData
                        required property int index
                        width: list.width - (bar.visible ? 8 : 0)
                        task: modelData
                        selected: root.selectedId === modelData.id
                        dragParent: root.dragParent ?? root
                        transform: Translate {
                            y: root.shiftOf(column.index, card.index)
                            Behavior on y {
                                NumberAnimation {
                                    duration: App.Config.anim.hover
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        onDragBegan: dragged => root.beginDrag(modelData.id, column.index, index, dragged)
                        onDragEnded: cancelled => root.endDrag(cancelled)
                        onClicked: root.taskClicked(modelData.id)
                        onOpened: root.taskOpened(modelData.id)
                    }
                }
            }
        }
    }
}
