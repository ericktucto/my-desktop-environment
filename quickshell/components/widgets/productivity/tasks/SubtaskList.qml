import QtQuick
import "../../../../services/tasks/" as TS
import "../../../../" as App

// Subtareas de una tarea (un solo nivel): marcar, borrar, subir o bajar con las flechas y añadir.
Column {
    id: root

    property string taskId: ""
    property var subtasks: []

    readonly property var store: TS.TaskStore
    readonly property int doneCount: subtasks.filter(s => s.done).length

    spacing: 2

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
            color: itemMouse.containsMouse ? App.Theme.surface : "transparent"

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
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
                anchors.right: actions.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: item.modelData.title
                elide: Text.ElideRight
                color: item.modelData.done ? App.Theme.gray : App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
                font.strikeout: item.modelData.done
            }
            Row {
                id: actions
                visible: itemMouse.containsMouse
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Repeater {
                    model: [
                        {
                            glyph: 0xf062,
                            step: -1
                        },
                        {
                            glyph: 0xf063,
                            step: 1
                        },
                        {
                            glyph: 0xf00d,
                            step: 0
                        }
                    ]
                    Rectangle {
                        id: act
                        required property var modelData
                        width: 22
                        height: 22
                        radius: 11
                        visible: !(modelData.step === -1 && item.index === 0) && !(modelData.step === 1 && item.index === root.subtasks.length - 1)
                        color: actMouse.containsMouse ? App.Theme.surfaceActive : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: String.fromCodePoint(act.modelData.glyph)
                            color: act.modelData.step === 0 && actMouse.containsMouse ? App.Theme.red : App.Theme.gray
                            font.family: App.Config.fonts.icons
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (act.modelData.step === 0)
                                    root.store.removeSubtask(root.taskId, item.modelData.id);
                                else
                                    root.store.moveSubtask(root.taskId, item.modelData.id, item.index + act.modelData.step);
                            }
                        }
                    }
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
