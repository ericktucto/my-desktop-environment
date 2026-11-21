import QtQuick
import Quickshell
import Quickshell.Io
import "../base" as Base
import "../widgets/workspaces/" as W
import "../../services/workspaces/" as S
import "../../services/actions/" as AC
import "../../services/settings/" as ST
import "../../" as App

Base.Island {
    id: root

    expandedHeight: S.WorkspaceStore.overviewHeight
    expandedWidth: S.WorkspaceStore.overviewWidth

    preventFocus: true

    Row {
        id: dots
        anchors.verticalCenter: parent.verticalCenter

        spacing: App.Config.workspaces.spacing
        Repeater {
            model: S.WorkspaceStore.count
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

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
            // Derecho y central según Preferencias → Barra e isla (por defecto: la vista general y nada)
            const id = mouse.button === Qt.RightButton ? ST.SettingsStore.wsPill.right : (mouse.button === Qt.MiddleButton ? ST.SettingsStore.wsPill.middle : "");
            if (mouse.button === Qt.LeftButton)
                S.WorkspaceStore.focus(nearest(mouse.x) + 1);
            else if (id === "workspaces")
                root.open();
            else
                AC.ActionRunner.run(id);
        }
        onWheel: wheel => {
            const dy = wheel.angleDelta.y;
            if (dy === 0)
                return;
            if (wheelAcc * dy < 0)
                wheelAcc = 0;
            wheelAcc += dy;
            while (Math.abs(wheelAcc) >= App.Config.workspaces.wheelStep) {
                AC.ActionRunner.wheel(ST.SettingsStore.wsPill.wheel, wheelAcc > 0 ? 1 : -1);
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
