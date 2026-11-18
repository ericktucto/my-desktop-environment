import QtQuick
import QtQuick.Controls
import "../../../../services/tasks/Dates.js" as Dates
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
    // Filas visibles: [{ kind: "header" | "task", id, task, label, extra, late }]
    property var rows: []

    signal taskClicked(string id)
    signal taskToggled(string id)
    signal taskOpened(string id)

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    spacing: 2
    model: rows
    cacheBuffer: 400

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
                    id: "h:" + g.key,
                    label: g.label,
                    extra: g.key === "overdue" ? "" : Dates.formatMinutes(est),
                    late: g.key === "overdue"
                });
            }
            for (const t of g.tasks)
                out.push({
                    kind: "task",
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
            if (x.kind !== y.kind || x.id !== y.id || x.task !== y.task || x.label !== y.label || x.extra !== y.extra)
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

    delegate: Loader {
        id: cell
        required property var modelData
        width: ListView.view.width
        sourceComponent: modelData.kind === "task" ? rowComponent : headerComponent

        Component {
            id: rowComponent
            TaskRow {
                task: cell.modelData.task
                selected: root.selectedId === cell.modelData.id
                showProject: root.showProject
                onClicked: root.taskClicked(cell.modelData.id)
                onToggled: root.taskToggled(cell.modelData.id)
                onOpened: root.taskOpened(cell.modelData.id)
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
                    color: cell.modelData.late ? App.Theme.red : App.Theme.gray
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
