import QtQuick
import "../../../../services/tasks/" as TS
import "../../../../services/tasks/Drop.js" as Drop
import "../../../../" as App

// Subtareas de una tarea (un solo nivel): marcar, borrar, ordenar arrastrando y añadir.
Column {
    id: root

    property string taskId: ""
    property var subtasks: []

    readonly property var store: TS.TaskStore
    readonly property int doneCount: subtasks.filter(s => s.done).length

    spacing: 2

    // Arrastre: la fila que se agarra sigue al puntero y las demás se corren para dejarle el hueco
    property int dragFrom: -1
    property int dragTo: -1
    readonly property real rowStep: 34
    // Fila antes de la cual se abre el hueco
    readonly property int dragAt: dragTo > dragFrom ? dragTo + 1 : dragTo

    // Esc dentro del campo: true si había texto o foco que soltar
    function back() {
        if (addInput.activeFocus || addInput.text !== "") {
            addInput.text = "";
            addInput.focus = false;
            return true;
        }
        return false;
    }

    Repeater {
        model: root.subtasks
        Rectangle {
            id: item
            required property var modelData
            required property int index
            width: root.width
            height: 32
            radius: 8
            color: itemMouse.containsMouse || item.dragging ? App.Theme.surface : "transparent"
            border.width: item.dragging ? 1 : 0
            border.color: App.Theme.primary
            z: item.dragging ? 10 : 0

            property real dragY: 0
            readonly property bool dragging: root.dragFrom === item.index
            transform: Translate {
                y: item.dragging ? item.dragY : (root.dragFrom >= 0 ? Drop.gapShift(item.index, root.dragFrom, root.dragAt, root.rowStep) : 0)
                Behavior on y {
                    enabled: !item.dragging
                    NumberAnimation {
                        duration: App.Config.anim.hover
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: item.dragging ? Qt.ClosedHandCursor : Qt.ArrowCursor
                property real pressPy: 0
                property bool moved: false
                onPressed: mouse => {
                    pressPy = mapToItem(root, mouse.x, mouse.y).y;
                    moved = false;
                }
                onPositionChanged: mouse => {
                    if (!pressed)
                        return;
                    const py = mapToItem(root, mouse.x, mouse.y).y;
                    if (!moved && Math.abs(py - pressPy) < 6)
                        return;
                    moved = true;
                    root.dragFrom = item.index;
                    item.dragY = py - pressPy;
                    root.dragTo = Math.max(0, Math.min(root.subtasks.length - 1, Math.floor(py / root.rowStep)));
                }
                function finish(apply) {
                    const from = root.dragFrom;
                    const to = root.dragTo;
                    root.dragFrom = -1;
                    root.dragTo = -1;
                    item.dragY = 0;
                    const was = moved;
                    moved = false;
                    if (apply && was && from >= 0 && to >= 0 && from !== to)
                        root.store.moveSubtask(root.taskId, item.modelData.id, to);
                }
                onReleased: finish(true)
                onCanceled: finish(false)
            }

            Rectangle {
                id: box
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                radius: 9
                color: item.modelData.done ? App.Theme.green : "transparent"
                border.width: 2
                border.color: item.modelData.done ? App.Theme.green : App.Theme.gray
                Text {
                    visible: item.modelData.done
                    anchors.centerIn: parent
                    text: String.fromCodePoint(0xf00c)
                    color: App.Theme.black
                    font.family: App.Config.fonts.icons
                    font.pixelSize: 9
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.store.toggleSubtask(root.taskId, item.modelData.id)
                }
            }
            Text {
                anchors.left: box.right
                anchors.leftMargin: 10
                anchors.right: del.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: item.modelData.title
                elide: Text.ElideRight
                color: item.modelData.done ? App.Theme.gray : App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
                font.strikeout: item.modelData.done
            }
            // Borrar (se ordena arrastrando la fila)
            Rectangle {
                id: del
                visible: itemMouse.containsMouse && !item.dragging
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                radius: 11
                color: delMouse.containsMouse ? App.Theme.surfaceActive : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: String.fromCodePoint(0xf00d)
                    color: delMouse.containsMouse ? App.Theme.red : App.Theme.gray
                    font.family: App.Config.fonts.icons
                    font.pixelSize: 11
                }
                MouseArea {
                    id: delMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.store.removeSubtask(root.taskId, item.modelData.id)
                }
            }
        }
    }

    Rectangle {
        width: root.width
        height: 32
        radius: 8
        color: "transparent"
        border.width: addInput.activeFocus ? 1 : 0
        border.color: App.Theme.primary

        Text {
            x: 11
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(0xf067)
            color: App.Theme.gray
            font.family: App.Config.fonts.icons
            font.pixelSize: App.Config.fontSize.sm
        }
        TextInput {
            id: addInput
            anchors.fill: parent
            anchors.leftMargin: 36
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            color: App.Theme.white
            selectionColor: App.Theme.primary
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            clip: true
            onAccepted: {
                root.store.addSubtask(root.taskId, text);
                text = "";
            }
        }
        Text {
            visible: addInput.text === ""
            anchors.fill: parent
            anchors.leftMargin: 36
            verticalAlignment: Text.AlignVCenter
            text: "Añadir subtarea…"
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
}
