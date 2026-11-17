import QtQuick
import "../controlcenter/" as CC
import "../../../../services/tasks/" as TS
import "../../../../services/tasks/Dates.js" as Dates
import "../../../../services/settings/" as ST
import "../../../../" as App

// Pestaña Tareas: barra lateral con las vistas y la lista a la derecha.
// Teclado (con la lista enfocada), estilo vim:
//   j/k o ↓/↑ mover · g/G primera/última · x o Espacio completar · n nueva · / buscar
//   dd borrar · 1–4 prioridad · t hoy · m mañana · s en curso · b bloqueada · u o Ctrl+Z deshacer
//   Alt+j / Alt+k reordenar (orden manual)
Item {
    id: root

    readonly property var store: TS.TaskStore
    readonly property var cfg: App.Config.tasks

    signal closeRequested

    focus: true

    // ── Vista ──
    readonly property string effectiveView: {
        const v = ST.SettingsStore.tasks.view;
        if (v.startsWith("project:")) {
            const p = store.project(v.slice(8));
            return p && !p.archived ? v : "today";
        }
        if (v.startsWith("tag:") || ["today", "upcoming", "inbox", "board", "done"].includes(v))
            return v;
        return "today";
    }
    readonly property string viewTitle: {
        const v = effectiveView;
        if (v.startsWith("project:"))
            return store.projectName(v.slice(8));
        if (v.startsWith("tag:"))
            return "#" + v.slice(4);
        return {
            today: "Hoy",
            upcoming: "Próximos " + cfg.upcomingDays + " días",
            inbox: "Bandeja",
            board: "Tablero",
            done: "Hechas"
        }[v];
    }
    readonly property string emptyText: {
        if (query.trim() !== "")
            return "Sin resultados";
        return {
            today: "Nada para hoy",
            upcoming: "Nada en los próximos días",
            inbox: "La bandeja está vacía",
            board: "Sin tareas",
            done: "Aún no hay tareas hechas"
        }[effectiveView] ?? "Sin tareas";
    }

    property string query: ""
    property bool searching: false
    // Tarea abierta en el detalle ("" = se ve la lista)
    property string detailId: ""
    property bool sortMenuOpen: false

    readonly property var groups: store.list(effectiveView, query)
    // Ids de las tareas en el orden en que se ven
    readonly property var ids: {
        const out = [];
        for (const g of groups)
            for (const t of g.tasks)
                out.push(t.id);
        return out;
    }

    // ── Selección ──
    property string selectedId: ""
    property int selIndex: 0
    readonly property var selected: selectedId !== "" ? store.get(selectedId) : null

    onIdsChanged: {
        const i = ids.indexOf(selectedId);
        if (i >= 0)
            selIndex = i;
        else
            selectedId = ids.length > 0 ? ids[Math.min(selIndex, ids.length - 1)] : "";
    }
    onSelectedIdChanged: Qt.callLater(() => root.effectiveView === "done" ? doneView.ensureVisible(selectedId) : list.ensureVisible(selectedId))
    onEffectiveViewChanged: {
        selIndex = 0;
        detailId = "";
        selectedId = ids && ids.length > 0 ? ids[0] : "";
        list.positionViewAtBeginning();
        doneView.positionViewAtBeginning();
    }

    function select(id) {
        selectedId = id;
        const i = ids.indexOf(id);
        if (i >= 0)
            selIndex = i;
    }

    function selectStep(step) {
        if (ids.length === 0)
            return;
        const i = ids.indexOf(selectedId);
        select(ids[Math.max(0, Math.min(ids.length - 1, (i < 0 ? 0 : i + step)))]);
    }

    function setView(v) {
        ST.SettingsStore.tasks.view = v;
        sortMenuOpen = false;
        focusList();
    }

    function focusList() {
        root.forceActiveFocus();
    }

    // ── Acciones sobre la tarea elegida ──
    function toggleDone() {
        const t = selected;
        if (!t)
            return;
        if (t.status === "done" || t.status === "cancelled")
            store.reopen(t.id);
        else
            store.complete(t.id);
    }

    function toggleStatus(status) {
        const t = selected;
        if (t)
            store.setStatus(t.id, t.status === status ? "todo" : status, "");
    }

    function setDay(offset) {
        const t = selected;
        if (t)
            store.update(t.id, {
                due: Dates.addDays(store.todayKey, offset)
            });
    }

    function deleteSelected() {
        const t = selected;
        if (t)
            store.remove(t.id, "this");
    }

    // Alt+j / Alt+k: sube o baja la tarea (solo en orden manual)
    function reorder(step) {
        const i = ids.indexOf(selectedId);
        const j = i + step;
        if (i < 0 || j < 0 || j >= ids.length || store.sortMode !== "manual")
            return;
        if (step > 0)
            store.moveAfter(selectedId, ids[j]);
        else
            store.move(selectedId, ids[j]);
    }

    // Valores de una tarea nueva según la vista donde se crea
    function addTask(text) {
        const f = {
            title: text
        };
        const v = effectiveView;
        if (v === "today")
            f.due = store.todayKey;
        else if (v === "upcoming")
            f.due = Dates.addDays(store.todayKey, 1);
        else if (v.startsWith("project:"))
            f.project = v.slice(8);
        else if (v.startsWith("tag:"))
            f.tags = [v.slice(4)];
        const id = store.add(f);
        if (id !== "")
            select(id);
    }

    function openDetail(id) {
        if (id === "" || !store.get(id))
            return;
        select(id);
        sortMenuOpen = false;
        detailId = id;
    }

    function closeDetail() {
        detailId = "";
        focusList();
    }

    // Esc: cierra lo que esté abierto; true si había algo
    function back() {
        if (detailId !== "") {
            if (!(detail.item?.back() ?? false))
                closeDetail();
            return true;
        }
        if (sortMenuOpen) {
            sortMenuOpen = false;
            return true;
        }
        if (sidebar.back())
            return true;
        if (addInput.activeFocus || addInput.text !== "") {
            addInput.text = "";
            focusList();
            return true;
        }
        if (searching) {
            closeSearch();
            return true;
        }
        return false;
    }

    function reset() {
        detail.item?.reset();
        detailId = "";
        sortMenuOpen = false;
        sidebar.back();
        addInput.text = "";
        closeSearch();
    }

    function openSearch() {
        searching = true;
        searchInput.forceActiveFocus();
    }

    function closeSearch() {
        searching = false;
        query = "";
        searchInput.text = "";
        focusList();
    }

    onActiveFocusChanged: pendingD.stop()

    Timer {
        id: pendingD
        interval: 700
    }

    Keys.onPressed: event => {
        if (event.modifiers & Qt.MetaModifier || detailId !== "")
            return;
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_Z) {
                store.undo();
                event.accepted = true;
            }
            return;
        }
        let used = true;
        const key = event.key;
        if (event.modifiers & Qt.AltModifier) {
            if (key === Qt.Key_J || key === Qt.Key_Down)
                reorder(1);
            else if (key === Qt.Key_K || key === Qt.Key_Up)
                reorder(-1);
            else
                used = false;
            event.accepted = used;
            return;
        }
        // dd: la segunda d (en menos de 0,7 s) borra
        if (key === Qt.Key_D) {
            if (pendingD.running) {
                pendingD.stop();
                deleteSelected();
            } else {
                pendingD.restart();
            }
            event.accepted = true;
            return;
        }
        pendingD.stop();
        if (event.text === "/")
            openSearch();
        else if (key === Qt.Key_J || key === Qt.Key_Down)
            selectStep(1);
        else if (key === Qt.Key_K || key === Qt.Key_Up)
            selectStep(-1);
        else if (key === Qt.Key_G && (event.modifiers & Qt.ShiftModifier))
            select(ids[ids.length - 1] ?? "");
        else if (key === Qt.Key_G || key === Qt.Key_Home)
            select(ids[0] ?? "");
        else if (key === Qt.Key_End)
            select(ids[ids.length - 1] ?? "");
        else if (key === Qt.Key_X || key === Qt.Key_Space)
            toggleDone();
        else if (key === Qt.Key_N)
            addInput.forceActiveFocus();
        else if (key >= Qt.Key_1 && key <= Qt.Key_4 && selected)
            store.update(selectedId, {
                priority: key - Qt.Key_0
            });
        else if (key === Qt.Key_T)
            setDay(0);
        else if (key === Qt.Key_M)
            setDay(1);
        else if (key === Qt.Key_S)
            toggleStatus("doing");
        else if (key === Qt.Key_B)
            toggleStatus("blocked");
        else if (key === Qt.Key_U)
            store.undo();
        else if (key === Qt.Key_E || key === Qt.Key_Return || key === Qt.Key_Enter)
            openDetail(selectedId);
        else
            used = false;
        event.accepted = used;
    }

    // ── Aviso "Tarea completada · Deshacer" ──
    property bool toastVisible: false

    Connections {
        target: root.store
        function onActed() {
            root.toastVisible = true;
            toastTimer.restart();
        }
    }
    Timer {
        id: toastTimer
        interval: root.cfg.undoTime
        onTriggered: root.toastVisible = false
    }

    // ── Barra lateral ──
    TaskSidebar {
        id: sidebar
        width: root.cfg.sidebarWidth
        height: parent.height
        view: root.effectiveView
        onViewSelected: v => root.setView(v)
        onEditingFinished: root.focusList()
    }

    Rectangle {
        id: separator
        x: sidebar.width + 6
        width: 1
        height: parent.height
        color: App.Theme.islandEdge
    }

    // ── Cabecera, campo para añadir y lista ──
    Item {
        id: main
        x: sidebar.width + 14
        width: parent.width - x
        height: parent.height

        Item {
            id: head
            visible: root.detailId === ""
            width: parent.width
            height: 32

            Row {
                visible: !root.searching
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.viewTitle
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.lg + 2
                    font.weight: Font.DemiBold
                }
                Text {
                    visible: root.effectiveView === "today" && root.store.todayEstimate > 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: Dates.formatMinutes(root.store.todayEstimate)
                    color: App.Theme.gray
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                }
            }

            // Búsqueda (tecla /)
            Rectangle {
                visible: root.searching
                anchors.left: parent.left
                anchors.right: tools.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 30
                radius: 15
                color: App.Theme.surface
                border.width: 1
                border.color: App.Theme.primary

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: App.Theme.white
                    selectionColor: App.Theme.primary
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                    clip: true
                    onTextChanged: root.query = text
                    onAccepted: root.focusList()
                }
                Text {
                    visible: searchInput.text === ""
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    verticalAlignment: Text.AlignVCenter
                    text: "Buscar…  +proyecto  #etiqueta  p1  vencidas  en curso"
                    elide: Text.ElideRight
                    color: App.Theme.placeholder
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                }
            }

            Row {
                id: tools
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                TaskIconButton {
                    glyph: root.searching ? 0xf00d : 0xf002
                    active: root.searching
                    onClicked: root.searching ? root.closeSearch() : root.openSearch()
                }
                TaskIconButton {
                    glyph: 0xf142
                    active: root.sortMenuOpen
                    onClicked: root.sortMenuOpen = !root.sortMenuOpen
                }
            }
        }

        // Aviso si tasks.json está roto (no se guarda hasta que se arregle)
        Text {
            id: errorText
            visible: root.store.error !== "" && root.detailId === ""
            y: head.height + 4
            width: parent.width
            wrapMode: Text.Wrap
            text: root.store.error + ". No se guardará nada hasta que lo arregles."
            color: App.Theme.red
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }

        // + Añadir tarea…
        Rectangle {
            id: addField
            visible: root.detailId === "" && root.effectiveView !== "done"
            y: head.height + 8 + (errorText.visible ? errorText.height + 8 : 0)
            width: parent.width
            height: 38
            radius: 12
            color: App.Theme.surface
            border.width: 1
            border.color: addInput.activeFocus ? App.Theme.primary : "transparent"
            enabled: root.store.error === ""

            Text {
                id: plus
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                text: String.fromCodePoint(0xf067)
                color: App.Theme.gray
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.icon - 3
            }
            TextInput {
                id: addInput
                anchors.fill: parent
                anchors.leftMargin: 38
                anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                color: App.Theme.white
                selectionColor: App.Theme.primary
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
                clip: true
                onAccepted: {
                    root.addTask(text);
                    text = "";
                }
            }
            Text {
                visible: addInput.text === ""
                anchors.fill: parent
                anchors.leftMargin: 38
                verticalAlignment: Text.AlignVCenter
                text: "Añadir tarea…"
                color: App.Theme.placeholder
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
            }
            MouseArea {
                anchors.fill: parent
                visible: !addInput.activeFocus
                cursorShape: Qt.IBeamCursor
                onClicked: addInput.forceActiveFocus()
            }
        }

        TaskList {
            id: list
            visible: root.detailId === "" && root.effectiveView !== "done"
            y: addField.y + addField.height + 8
            width: parent.width
            height: parent.height - y
            groups: root.groups
            selectedId: root.selectedId
            showHeaders: root.groups.length > 1 || ["today", "upcoming", "done", "board"].includes(root.effectiveView)
            showProject: !root.effectiveView.startsWith("project:")
            emptyText: root.emptyText
            onTaskClicked: id => {
                root.select(id);
                root.focusList();
            }
            onTaskToggled: id => {
                root.select(id);
                root.focusList();
                root.toggleDone();
            }
            onTaskOpened: id => root.openDetail(id)
        }

        DoneView {
            id: doneView
            visible: root.detailId === "" && root.effectiveView === "done"
            y: head.height + 8 + (errorText.visible ? errorText.height + 8 : 0)
            width: parent.width
            height: parent.height - y
            groups: root.groups
            selectedId: root.selectedId
            todayKey: root.store.todayKey
            emptyText: root.emptyText
            onTaskClicked: id => {
                root.select(id);
                root.focusList();
            }
            onTaskToggled: id => {
                root.select(id);
                root.focusList();
                root.toggleDone();
            }
            onTaskOpened: id => root.openDetail(id)
        }

        // Detalle de la tarea (reemplaza a la lista)
        Loader {
            id: detail
            anchors.fill: parent
            active: root.detailId !== ""
            sourceComponent: TaskDetail {
                taskId: root.detailId
                onCloseRequested: root.closeDetail()
            }
        }

        // Menú ⋮: orden de las listas
        MouseArea {
            anchors.fill: parent
            visible: root.sortMenuOpen
            z: 19
            onClicked: root.sortMenuOpen = false
        }
        Rectangle {
            visible: root.sortMenuOpen
            z: 20
            anchors.right: parent.right
            y: head.height + 4
            width: 200
            height: sortColumn.implicitHeight + 12
            radius: 14
            color: App.Theme.island
            border.color: App.Theme.islandEdge
            border.width: 1

            Column {
                id: sortColumn
                x: 6
                y: 6
                width: parent.width - 12
                spacing: 2

                Text {
                    leftPadding: 8
                    topPadding: 2
                    bottomPadding: 4
                    text: "ORDENAR POR"
                    color: App.Theme.grayDark
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.6
                }
                Repeater {
                    model: [
                        {
                            id: "manual",
                            label: "Orden manual"
                        },
                        {
                            id: "due",
                            label: "Fecha"
                        },
                        {
                            id: "priority",
                            label: "Prioridad"
                        }
                    ]
                    Rectangle {
                        required property var modelData
                        width: sortColumn.width
                        height: 30
                        radius: 8
                        color: sortMouse.containsMouse ? App.Theme.surfaceActive : "transparent"
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            text: parent.modelData.label
                            color: App.Theme.white
                            font.family: App.Config.fonts.text
                            font.pixelSize: App.Config.fontSize.sm
                        }
                        Text {
                            visible: root.store.sortMode === parent.modelData.id
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            text: String.fromCodePoint(0xf00c)
                            color: App.Theme.primary
                            font.family: App.Config.fonts.icons
                            font.pixelSize: App.Config.fontSize.sm
                        }
                        MouseArea {
                            id: sortMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ST.SettingsStore.tasks.sort = parent.modelData.id;
                                root.sortMenuOpen = false;
                            }
                        }
                    }
                }
            }
        }

        // Aviso de deshacer
        Rectangle {
            id: toast
            z: 30
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            width: toastRow.implicitWidth + 28
            height: 34
            radius: 17
            color: App.Theme.island
            border.color: App.Theme.islandEdge
            border.width: 1
            opacity: root.toastVisible && root.store.lastAction !== "" ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: App.Config.anim.hover
                }
            }

            Row {
                id: toastRow
                anchors.centerIn: parent
                spacing: 12
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.store.lastAction
                    color: App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Deshacer"
                    color: App.Theme.primary
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                    font.weight: Font.DemiBold
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.store.undo();
                            root.toastVisible = false;
                        }
                    }
                }
            }
        }
    }
}
