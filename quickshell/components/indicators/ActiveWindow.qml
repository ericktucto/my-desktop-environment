import QtQuick
import QtQuick.Controls
import "../base" as Base
import "../widgets/window/" as WW
import "../../services/windows/" as WS
import "../../services/actions/" as AC
import "../../services/settings/" as ST
import "../../" as App

// Pill de la ventana activa: ícono, nombre de la app y su título. El clic izquierdo abre la isla en la pestaña
// App, el derecho en la pestaña Ventana (acciones sobre la ventana) y el central cierra la ventana.
Base.Island {
    id: root

    // La vista general de workspaces ya muestra las ventanas (y empujaría la pill hasta el reloj)
    property bool workspacesOpen: false

    readonly property var store: WS.ActiveWindowStore

    visible: (ST.SettingsStore.pills.activeWindow && store.visible && !workspacesOpen) || expanded
    openOnClick: false

    expandedWidth: App.Config.activeWindow.panelWidth
    expandedHeight: panel.implicitHeight + 2 * paddingContainer
    paddingContainer: App.Config.media.padding
    preventFocus: true
    // Esc: primero cancela lo que esté a medias (p. ej. el segundo clic de Forzar cierre)
    escapeBack: function () {
        return panel.back();
    }

    function openTab(tab) {
        if (!store.visible)
            return;
        store.lock();
        panel.tab = tab;
        open();
    }

    // La ventana se cerró (o se fue) con la isla abierta: se cierra también
    Connections {
        target: root.store
        function onTargetWindowChanged() {
            if (root.expanded && root.store.targetWindow === null)
                root.close();
        }
    }
    // Atajo (Super+. / Super+Shift+.): abre en esa pestaña; si ya está abierta en ella, cierra; si no, cambia
    Connections {
        target: root.store
        function onToggleRequested(tab) {
            if (!root.expanded)
                root.openTab(tab);
            else if (panel.tab === tab)
                root.close();
            else
                panel.tab = tab;
        }
    }
    // El teclado va al panel (letras subrayadas, ↑↓, Enter y Tab)
    onOpened: Qt.callLater(() => panel.forceActiveFocus())
    onClosed: store.unlock()

    // Lo que cabe para el texto: el máximo menos el ícono, el relleno y los espacios
    readonly property real textMax: App.Config.activeWindow.maxWidth - 2 * App.Config.pill.paddingX - App.Config.activeWindow.iconSize - App.Config.pill.contentSpacing

    Image {
        anchors.verticalCenter: parent.verticalCenter
        source: root.store.icon
        sourceSize: Qt.size(App.Config.activeWindow.iconSize, App.Config.activeWindow.iconSize)
        width: App.Config.activeWindow.iconSize
        height: App.Config.activeWindow.iconSize
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            id: nameText
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.textMax)
            text: root.store.name
            elide: Text.ElideRight
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.DemiBold
        }
        Text {
            id: titleText
            visible: text !== "" && root.textMax - nameText.width - parent.spacing > 24
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.textMax - nameText.width - parent.spacing)
            text: root.store.title
            elide: Text.ElideRight
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
    }

    // parent: root porque los hijos de Island van a un Row (anchors.fill lo rompe)
    MouseArea {
        parent: root
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.expanded
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            // Según Preferencias → Barra e isla (por defecto: izquierdo menú de la app, derecho el de la ventana y
            // central cierra la ventana)
            const c = ST.SettingsStore.windowPill;
            const id = mouse.button === Qt.MiddleButton ? c.middle : (mouse.button === Qt.RightButton ? c.right : c.left);
            if (id === "windowApp")
                root.openTab("app");
            else if (id === "windowMenu")
                root.openTab("window");
            else
                AC.ActionRunner.run(id);
        }

        ToolTip.visible: containsMouse
        ToolTip.delay: App.Config.activeWindow.tooltipDelay
        ToolTip.text: (root.store.title !== "" ? root.store.name + " · " + root.store.title : root.store.name) + "\nClic: app · Clic derecho: ventana · Clic central: cerrar"
    }

    body: WW.WindowPanel {
        id: panel
        width: parent ? parent.width : 0
        onCloseRequested: root.close()
    }
}
