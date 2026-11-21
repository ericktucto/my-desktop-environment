import QtQuick
import QtQuick.Controls
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

    // El estilo elegido en Preferencias → Barra e isla (los que aún no existen caen en Puntos)
    readonly property var styleDef: S.WorkspaceStore.styles.find(d => d.id === ST.SettingsStore.workspaces.style) ?? S.WorkspaceStore.styles[0]

    Loader {
        id: styleLoader
        anchors.verticalCenter: parent.verticalCenter
        source: "workspaces/" + root.styleDef.source
        // La numeración (Números, japoneses y romanos comparten Numbers.qml, así que no se recarga al cambiar)
        Binding {
            target: styleLoader.item
            property: "numerals"
            value: root.styleDef.numerals ?? "arabic"
            when: styleLoader.item !== null && root.styleDef.numerals !== undefined
        }
        Binding {
            target: styleLoader.item
            property: "hoverId"
            value: area.hoverId
            when: styleLoader.item !== null
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

        // Al pasar el mouse sobre un workspace: su número y sus apps
        ToolTip.visible: hoverId > 0 && !root.expanded
        ToolTip.delay: App.Config.activeWindow.tooltipDelay
        ToolTip.text: {
            const it = S.WorkspaceStore.items.find(i => i.id === hoverId);
            if (!it)
                return "";
            const names = it.apps.map(a => a.name).filter((n, i, arr) => n !== "" && arr.indexOf(n) === i);
            return hoverId + " · " + (names.length > 0 ? names.join(", ") : "vacío");
        }
        // El workspace bajo el mouse (0 = ninguno)
        readonly property int hoverId: containsMouse && styleLoader.item ? Math.max(0, styleLoader.item.idAt(styleLoader.mapFromItem(area, mouseX, 0).x)) : 0

        onClicked: mouse => {
            // Derecho y central según Preferencias → Barra e isla (por defecto: la vista general y nada)
            const id = mouse.button === Qt.RightButton ? ST.SettingsStore.wsPill.right : (mouse.button === Qt.MiddleButton ? ST.SettingsStore.wsPill.middle : "");
            if (mouse.button === Qt.LeftButton) {
                // Sin a qué apuntar (estilo Mínimo), el clic abre la vista general
                const target = styleLoader.item ? styleLoader.item.idAt(styleLoader.mapFromItem(area, mouse.x, 0).x) : -1;
                if (target > 0)
                    S.WorkspaceStore.focus(target);
                else
                    root.open();
            } else if (id === "workspaces")
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
            // qs ipc call stixshell@workspaces style <id>|next|prev
            function style(id: string): string {
                const list = S.WorkspaceStore.styles;
                const i = Math.max(0, list.findIndex(d => d.id === ST.SettingsStore.workspaces.style));
                const next = id === "next" ? list[(i + 1) % list.length] : id === "prev" ? list[(i - 1 + list.length) % list.length] : list.find(d => d.id === id);
                if (!next)
                    return "estilos: " + list.map(d => d.id).join(", ");
                ST.SettingsStore.workspaces.style = next.id;
                return next.id;
            }
        }
    }
}
