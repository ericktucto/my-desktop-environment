import QtQuick
import Quickshell
import Quickshell.Io
import "../base" as Base
import "../widgets/workspaces/" as W
import "../../services/workspaces/" as S
import "../../" as App

Base.Island {
    id: root

    expandedHeight: S.WorkspaceStore.overviewHeight
    expandedWidth: App.Config.workspaces.overviewWidth

    preventFocus: true

    Row {
        id: dots
        anchors.verticalCenter: parent.verticalCenter

        spacing: App.Config.workspaces.spacing
        Repeater {
            model: App.Config.workspaces.count
            delegate: Rectangle {
                id: dot
                required property int index
                readonly property var ws: S.WorkspaceStore.workspace(index + 1)
                readonly property bool active: S.WorkspaceStore.currentId === index + 1
                readonly property bool hasWindows: (ws?.toplevels?.values?.length ?? 0) > 0
                readonly property bool hovered: index === area.hoverIndex

                width: active ? App.Config.workspaces.activeWidth : App.Config.workspaces.dotSize
                height: App.Config.workspaces.dotSize
                color: active ? App.Theme.primary : hasWindows ? App.Theme.white : (hovered ? App.Theme.surfaceActive : 'transparent')
                border.color: App.Theme.white
                border.width: active ? 0 : 1
                radius: App.Config.workspaces.dotSize
                opacity: hovered && !active ? 1 : 0.9

                Behavior on width {
                    NumberAnimation {
                        duration: App.Config.anim.pill
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    // Pill cerrada: clic izquierdo = ir al workspace del punto más cercano,
    // rueda = anterior/siguiente (se detiene en los extremos), clic derecho = vista general.
    // parent: root porque los hijos de Island van a un Row (anchors.fill lo rompe).
    MouseArea {
        id: area
        parent: root
        anchors.fill: parent
        enabled: !root.expanded
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property real wheelAcc: 0
        readonly property int hoverIndex: containsMouse ? nearest(mouseX) : -1

        // Punto cuyo centro está más cerca de x (x en coordenadas de la pill)
        function nearest(x) {
            let best = 0, bestDist = Infinity;
            for (let i = 0; i < dots.children.length - 1; i++) {
                const d = dots.children[i];
                if (!d || d.index === undefined)
                    continue;
                const c = dots.mapToItem(root, d.x + d.width / 2, 0).x;
                const dist = Math.abs(c - x);
                if (dist < bestDist) {
                    bestDist = dist;
                    best = d.index;
                }
            }
            return best;
        }

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.open();
            else
                S.WorkspaceStore.focus(nearest(mouse.x) + 1);
        }
        onWheel: wheel => {
            const dy = wheel.angleDelta.y;
            if (dy === 0)
                return;
            if (wheelAcc * dy < 0)
                wheelAcc = 0;
            wheelAcc += dy;
            while (Math.abs(wheelAcc) >= App.Config.workspaces.wheelStep) {
                const dir = wheelAcc > 0 ? -1 : 1;   // abajo = siguiente
                S.WorkspaceStore.step(dir);
                wheelAcc -= (wheelAcc > 0 ? 1 : -1) * App.Config.workspaces.wheelStep;
            }
            wheel.accepted = true;
        }
    }

    body: W.WorkspaceOverview {
        anchors.fill: parent
        onDone: root.close()
        IpcHandler {
            target: "stixshell@workspaces"
            function toggle(mon: string): void {
                if (root.expanded)
                    root.close();
                else
                    root.open();
            }
        }
    }
}
