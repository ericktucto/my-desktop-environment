import QtQuick
import "../../../services/workspaces/" as S
import "../../../" as App

// Fila de una ventana (ícono + título): clic = enfocarla, arrastrar = moverla a otro workspace.
Item {
    id: root

    property var toplevel
    // Item al que se re-parenta mientras se arrastra (queda sobre las otras tarjetas)
    property Item dragParent

    signal activated

    readonly property var cfg: App.Config.workspaces
    readonly property bool dragging: mouse.drag.active

    height: cfg.rowHeight

    // La fila que se arrastra; `root` solo reserva su sitio en la tarjeta
    Rectangle {
        id: row
        width: root.width
        height: root.height
        radius: App.Config.radius.md
        color: root.dragging ? App.Theme.surfaceHigh : (mouse.containsMouse ? App.Theme.surfaceHover : "transparent")
        opacity: root.dragging ? 0.95 : 1

        property var toplevel: root.toplevel

        Drag.active: mouse.drag.active
        Drag.keys: ["stixshell-window"]
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        Behavior on color {
            ColorAnimation {
                duration: App.Config.anim.hover
            }
        }

        Image {
            id: img
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            width: root.cfg.iconSize
            height: root.cfg.iconSize
            source: root.toplevel ? S.WorkspaceStore.appIcon(root.toplevel) : ""
            sourceSize: Qt.size(root.cfg.iconSize, root.cfg.iconSize)
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Text {
            anchors.left: img.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.toplevel ? S.WorkspaceStore.titleOf(root.toplevel) : ""
            elide: Text.ElideRight
            color: App.Theme.text
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }

        states: State {
            when: root.dragging
            ParentChange {
                target: row
                parent: root.dragParent
            }
            PropertyChanges {
                target: row
                z: 1000
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        drag.target: row
        drag.threshold: 6

        onReleased: {
            row.Drag.drop();
            row.x = 0;
            row.y = 0;
        }
        onClicked: {
            S.WorkspaceStore.focusWindow(root.toplevel);
            root.activated();
        }
    }
}
