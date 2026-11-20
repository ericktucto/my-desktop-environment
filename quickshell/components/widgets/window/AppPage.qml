import QtQuick
import "../controlcenter/" as CC
import "../../../services/windows/" as WS
import "../../../services/workspaces/" as W
import "../../../" as App

// Pestaña «App»: acciones del .desktop (Nueva ventana…), las ventanas de la misma app, atajos de edición que
// se mandan a la ventana (Deshacer, Copiar, Pegar…; se ajustan por app en Config.activeWindow) e información.
// Hyprland no deja leer el menú «Archivo, Editar…» de la app: esto es lo que sí se puede ofrecer.
Column {
    id: root

    readonly property var store: WS.ActiveWindowStore
    readonly property var info: store.info
    readonly property var windows: store.sameApp
    property bool copied: false

    spacing: 8

    signal closeRequested

    function back() {
        return false;
    }

    // Hace la acción y cierra la isla
    function act(fn) {
        fn();
        closeRequested();
    }

    component Section: Text {
        color: App.Theme.grayDark
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
    }

    // Una fila de la lista (acción o ventana)
    component ListRow: Rectangle {
        id: row
        property string label: ""
        property string trailing: ""
        property bool current: false
        signal clicked

        width: parent.width
        height: 30
        radius: 10
        color: rowMouse.containsMouse ? App.Theme.surfaceActive : "transparent"

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: trail.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: row.label
            elide: Text.ElideRight
            color: row.current ? App.Theme.primary : App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
        Text {
            id: trail
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: row.trailing
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }

    Section {
        text: "ABRIR"
    }
    Column {
        width: parent.width
        Repeater {
            model: root.store.desktopActions
            ListRow {
                required property var modelData
                label: modelData.name
                onClicked: root.act(() => modelData.execute())
            }
        }
        // Sin acciones en el .desktop
        ListRow {
            visible: root.store.desktopActions.length === 0
            label: "Abrir otra instancia"
            onClicked: root.act(() => root.store.newInstance())
        }
    }

    Section {
        text: "VENTANAS"
    }
    Column {
        width: parent.width
        Repeater {
            model: root.windows.slice(0, 6)
            ListRow {
                required property var modelData
                label: W.WorkspaceStore.titleOf(modelData) || root.store.name
                trailing: String(modelData.workspace?.id ?? "")
                current: modelData.address === root.store.targetAddress
                onClicked: root.act(() => root.store.focusWindow(modelData))
            }
        }
        Text {
            visible: root.windows.length <= 1
            leftPadding: 10
            text: "Solo esta ventana"
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
    }

    Section {
        text: "EDITAR"
    }
    Flow {
        width: parent.width
        spacing: 6
        Repeater {
            model: root.store.shortcuts
            CC.Chip {
                required property var modelData
                label: modelData.label
                onClicked: {
                    root.store.sendShortcutLater(modelData.keys);
                    root.closeRequested();
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: App.Theme.islandEdge
    }

    // Información de la ventana; el clic copia la clase (sirve para escribir reglas de ventana)
    Item {
        width: parent.width
        height: 30

        Text {
            anchors.left: parent.left
            anchors.right: copy.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: [root.store.className, root.info.pid ? "PID " + root.info.pid : "", root.info.xwayland ? "Xwayland" : "Wayland", root.info.workspace ? "ws " + root.info.workspace.name : ""].filter(x => x !== "").join(" · ")
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.xs
        }
        CC.Chip {
            id: copy
            anchors.right: parent.right
            height: 26
            radius: 13
            label: root.copied ? "Copiada ✓" : "Copiar clase"
            onClicked: {
                root.store.copyClass();
                root.copied = true;
                copiedTimer.restart();
            }
        }
        Timer {
            id: copiedTimer
            interval: 1500
            onTriggered: root.copied = false
        }
    }
}
