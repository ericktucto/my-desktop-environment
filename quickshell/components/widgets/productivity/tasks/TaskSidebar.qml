import QtQuick
import "../../../../services/tasks/" as TS
import "../../../../" as App

// Barra lateral: las vistas, los proyectos (con "+") y las etiquetas, cada uno con su contador.
// Clic derecho en un proyecto: renombrar, cambiar el color o archivar.
Item {
    id: root

    readonly property var store: TS.TaskStore
    // La vista activa: today | upcoming | inbox | board | done | project:<id> | tag:<nombre>
    property string view: ""

    signal viewSelected(string view)
    signal editingFinished

    // true mientras se escribe el nombre de un proyecto
    readonly property bool editing: nameField.visible
    readonly property bool menuOpen: menu.visible

    readonly property var fixedViews: [
        {
            id: "today",
            label: "Hoy",
            glyph: 0xf185,
            count: store.counts.today,
            alert: store.counts.overdue > 0
        },
        {
            id: "upcoming",
            label: "Próximos",
            glyph: 0xf073,
            count: store.counts.upcoming
        },
        {
            id: "inbox",
            label: "Bandeja",
            glyph: 0xf01c,
            count: store.counts.inbox
        },
        {
            id: "board",
            label: "Tablero",
            glyph: 0xf0db,
            count: 0
        },
        {
            id: "done",
            label: "Hechas",
            glyph: 0xf00c,
            count: 0
        }
    ]

    // Cierra lo que esté abierto aquí (Esc); true si había algo
    function back() {
        if (menu.visible) {
            menu.visible = false;
            return true;
        }
        if (nameField.visible) {
            cancelName();
            return true;
        }
        return false;
    }

    // ── Nombre de proyecto (nuevo o renombrado) ──
    property string renamingId: ""

    function startName(id, text) {
        menu.visible = false;
        renamingId = id;
        nameInput.text = text;
        nameField.visible = true;
        nameInput.forceActiveFocus();
        nameInput.selectAll();
    }

    function cancelName() {
        nameField.visible = false;
        renamingId = "";
        nameInput.text = "";
        root.editingFinished();
    }

    function acceptName() {
        const text = nameInput.text.trim();
        const id = renamingId;
        nameField.visible = false;
        renamingId = "";
        nameInput.text = "";
        if (text !== "") {
            if (id === "") {
                const pid = store.addProject(text, "");
                if (pid !== "")
                    root.viewSelected("project:" + pid);
            } else {
                store.updateProject(id, {
                    name: text
                });
            }
        }
        root.editingFinished();
    }

    component Entry: Rectangle {
        id: entry
        property string label: ""
        property int glyph: 0
        property string mark: ""
        property color dot: "transparent"
        property int count: 0
        property bool alert: false
        property bool selected: false

        signal clicked
        signal rightClicked

        width: parent ? parent.width : 0
        height: 32
        radius: 10
        color: selected ? App.Theme.surfaceActive : (entryMouse.containsMouse ? App.Theme.surface : "transparent")

        Text {
            visible: entry.glyph !== 0
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            text: String.fromCodePoint(entry.glyph || 0x20)
            color: entry.selected ? App.Theme.white : App.Theme.gray
            font.family: App.Config.fonts.icons
            font.pixelSize: App.Config.fontSize.icon - 2
        }
        Rectangle {
            visible: entry.dot.a > 0
            x: 13
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: 5
            color: entry.dot
        }
        Text {
            visible: entry.mark !== ""
            x: 11
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            text: entry.mark
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
        }
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 36
            anchors.right: countText.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: entry.label
            elide: Text.ElideRight
            color: entry.selected ? App.Theme.white : App.Theme.text
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: entry.selected ? Font.DemiBold : Font.Normal
        }
        Text {
            id: countText
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: entry.count > 0 ? String(entry.count) : ""
            color: entry.alert ? App.Theme.red : App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: entry.alert ? Font.DemiBold : Font.Normal
        }
        MouseArea {
            id: entryMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => mouse.button === Qt.RightButton ? entry.rightClicked() : entry.clicked()
        }
    }

    component Section: Item {
        id: section
        property string label: ""
        property bool plus: false
        signal plusClicked

        width: parent ? parent.width : 0
        height: 30

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            text: section.label
            color: App.Theme.grayDark
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.xs
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
        }
        TaskIconButton {
            visible: section.plus
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 2
            size: 22
            glyph: 0xf067
            onClicked: section.plusClicked()
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column
            width: flick.width
            spacing: 2

            Repeater {
                model: root.fixedViews
                Entry {
                    required property var modelData
                    label: modelData.label
                    glyph: modelData.glyph
                    count: modelData.count
                    alert: modelData.alert ?? false
                    selected: root.view === modelData.id
                    onClicked: root.viewSelected(modelData.id)
                }
            }

            Item {
                width: 1
                height: 6
            }
            Section {
                label: "PROYECTOS"
                plus: true
                onPlusClicked: root.startName("", "")
            }

            Repeater {
                model: root.store.activeProjects
                Entry {
                    required property var modelData
                    visible: !(nameField.visible && root.renamingId === modelData.id)
                    height: visible ? 32 : 0
                    label: modelData.name
                    dot: modelData.color
                    count: root.store.counts.projects[modelData.id] ?? 0
                    selected: root.view === "project:" + modelData.id
                    onClicked: root.viewSelected("project:" + modelData.id)
                    onRightClicked: {
                        menu.projectId = modelData.id;
                        menu.y = Math.min(y + height - flick.contentY, root.height - menu.height);
                        menu.visible = true;
                    }
                }
            }

            // Campo para el nombre de un proyecto nuevo (o el que se renombra)
            Rectangle {
                id: nameField
                visible: false
                width: parent.width
                height: 32
                radius: 10
                color: App.Theme.surface
                border.width: 1
                border.color: App.Theme.primary

                TextInput {
                    id: nameInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: App.Theme.white
                    selectionColor: App.Theme.primary
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                    clip: true
                    onAccepted: root.acceptName()
                }
                Text {
                    visible: nameInput.text === ""
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    text: "Nombre del proyecto"
                    color: App.Theme.placeholder
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                }
            }

            Item {
                visible: root.store.tagNames.length > 0
                width: 1
                height: 6
            }
            Section {
                visible: root.store.tagNames.length > 0
                label: "ETIQUETAS"
            }
            Repeater {
                model: root.store.tagNames
                Entry {
                    required property string modelData
                    label: modelData
                    mark: "#"
                    count: root.store.counts.tags[modelData] ?? 0
                    selected: root.view === "tag:" + modelData
                    onClicked: root.viewSelected("tag:" + modelData)
                }
            }
        }
    }

    // Menú de un proyecto (clic derecho)
    MouseArea {
        anchors.fill: parent
        visible: menu.visible
        z: 19
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: menu.visible = false
    }

    Rectangle {
        id: menu
        visible: false
        z: 20
        property string projectId: ""
        x: 8
        width: parent.width - 16
        height: menuColumn.implicitHeight + 12
        radius: 14
        color: App.Theme.island
        border.color: App.Theme.border
        border.width: 1

        Column {
            id: menuColumn
            x: 6
            y: 6
            width: parent.width - 12
            spacing: 2

            Repeater {
                model: [
                    {
                        id: "rename",
                        label: "Renombrar"
                    },
                    {
                        id: "archive",
                        label: "Archivar"
                    }
                ]
                Rectangle {
                    required property var modelData
                    width: menuColumn.width
                    height: 30
                    radius: 8
                    color: itemMouse.containsMouse ? App.Theme.surfaceActive : "transparent"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        text: parent.modelData.label
                        color: App.Theme.white
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.sm
                    }
                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const id = menu.projectId;
                            if (parent.modelData.id === "rename") {
                                root.startName(id, root.store.projectName(id));
                            } else {
                                menu.visible = false;
                                root.store.archiveProject(id);
                                if (root.view === "project:" + id)
                                    root.viewSelected("today");
                            }
                        }
                    }
                }
            }

            // Colores
            Flow {
                width: parent.width
                spacing: 6
                topPadding: 6
                bottomPadding: 4
                leftPadding: 8
                Repeater {
                    model: root.store.projectColors
                    Rectangle {
                        required property string modelData
                        width: 16
                        height: 16
                        radius: 8
                        color: modelData
                        border.width: root.store.project(menu.projectId)?.color === modelData ? 2 : 0
                        border.color: App.Theme.white
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.store.updateProject(menu.projectId, {
                                    color: parent.modelData
                                });
                                menu.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
