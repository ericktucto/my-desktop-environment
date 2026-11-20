import QtQuick
import QtQuick.Controls
import "../../../../services/tasks/" as TS
import "../../../../" as App

// Tablero: una columna por estado (Pendiente · En curso · Bloqueada · Hecha hoy). Se arrastra una
// tarjeta a otra columna para cambiarle el estado (a Bloqueada, el panel pregunta el motivo).
// Arriba, un filtro por proyecto.
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

    signal taskClicked(string id)
    signal taskOpened(string id)
    // Una tarjeta soltada en otra columna
    signal moved(string id, string status)
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
                // Las columnas se buscan por su ListView
                function positionViewAtIndex(i, mode) {
                    list.positionViewAtIndex(i, mode);
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.width: drop.containsDrag ? 2 : 0
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
                    delegate: TaskCard {
                        required property var modelData
                        width: list.width - (bar.visible ? 8 : 0)
                        task: modelData
                        selected: root.selectedId === modelData.id
                        dragParent: root.dragParent ?? root
                        onClicked: root.taskClicked(modelData.id)
                        onOpened: root.taskOpened(modelData.id)
                    }
                }

                DropArea {
                    id: drop
                    anchors.fill: parent
                    keys: ["task"]
                    onDropped: dropEvent => {
                        const id = dropEvent.source.taskId;
                        const t = root.store.get(id);
                        if (id && t && t.status !== column.modelData.key)
                            root.moved(id, column.modelData.key);
                    }
                }
            }
        }
    }
}
