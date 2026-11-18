import QtQuick
import "../../../../services/tasks/" as TS
import "../../../../services/tasks/Dates.js" as Dates
import "../../../../" as App

// Una tarea como tarjeta del Tablero. Se arrastra a otra columna (cambia de estado); mientras se
// arrastra pasa a `dragParent` para poder salir de su columna.
Item {
    id: root

    property var task
    property bool selected: false
    // Item donde vive la tarjeta mientras se arrastra (el tablero entero)
    property Item dragParent

    signal clicked
    signal opened

    readonly property var store: TS.TaskStore
    readonly property bool overdue: Dates.isOverdue(task, store.now)
    readonly property alias dragging: dragArea.drag.active
    readonly property var project: store.project(task.project)

    height: card.height
    z: dragging ? 100 : 0

    Rectangle {
        id: card
        width: root.width
        height: content.implicitHeight + 16
        radius: 10
        color: root.selected ? App.Theme.surfaceActive : (dragArea.containsMouse ? App.Theme.surfaceHigh : App.Theme.surface)
        border.width: root.dragging ? 1 : 0
        border.color: App.Theme.primary
        opacity: root.dragging ? 0.9 : 1

        // Se saca de la columna mientras se arrastra
        Drag.active: dragArea.drag.active
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        property string taskId: root.task.id

        states: State {
            when: root.dragging
            ParentChange {
                target: card
                parent: root.dragParent
            }
        }

        Column {
            id: content
            x: 10
            y: 8
            width: parent.width - 20
            spacing: 4

            Text {
                width: parent.width
                text: root.task.title
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: root.task.status === "done" ? App.Theme.gray : App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
                font.weight: Font.Medium
                font.strikeout: root.task.status === "done"
            }
            Text {
                visible: root.task.status === "blocked" && root.task.blockedReason !== ""
                width: parent.width
                text: root.task.blockedReason
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: App.Theme.amber
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.xs
            }
            Flow {
                width: parent.width
                spacing: 8
                Text {
                    visible: root.task.due !== "" && root.task.status !== "done"
                    text: Dates.relative(root.task.due, root.task.dueTime, root.store.now)
                    color: root.overdue ? App.Theme.red : App.Theme.gray
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                }
                Text {
                    visible: root.task.priority < 4
                    text: "p" + root.task.priority
                    color: App.Config.tasks.priorityColors[String(root.task.priority)]
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                    font.weight: Font.DemiBold
                }
                Row {
                    visible: root.project !== null
                    spacing: 4
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6
                        height: 6
                        radius: 3
                        color: root.project ? root.project.color : "transparent"
                    }
                    Text {
                        text: root.project ? root.project.name : ""
                        color: App.Theme.gray
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.xs
                    }
                }
                Text {
                    visible: root.task.subtasks.length > 0
                    text: root.task.subtasks.filter(s => s.done).length + "/" + root.task.subtasks.length
                    color: App.Theme.gray
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                }
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        drag.target: card
        onClicked: root.clicked()
        onDoubleClicked: root.opened()
        // Al soltar: se avisa a la columna donde cae y la tarjeta vuelve a su sitio (el estado la
        // reencuentra en su lugar cuando el modelo se actualiza)
        drag.onActiveChanged: {
            if (!drag.active) {
                card.Drag.drop();
                Qt.callLater(() => {
                    card.x = 0;
                    card.y = 0;
                });
            }
        }
    }
}
