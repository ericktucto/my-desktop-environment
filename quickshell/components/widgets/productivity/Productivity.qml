import QtQuick
import "tasks" as TK
import "../controlcenter/" as CC
import "../../../services/settings/" as ST
import "../../../" as App

// Modo "productivity" de la isla central: la barra de pestañas (Calendario · Tareas) y la pestaña activa.
// La pestaña se recuerda en settings.json (tasks.lastTab), así Super+P abre la última usada.
// Teclado: Ctrl+Tab alterna las pestañas. El ancho de la isla cambia con la pestaña; el alto es el mismo.
Item {
    id: root

    signal closeRequested

    readonly property var tabs: [
        {
            id: "calendar",
            label: "Calendario"
        },
        {
            id: "tasks",
            label: "Tareas"
        }
    ]
    readonly property string tab: ST.SettingsStore.tasks.lastTab === "tasks" ? "tasks" : "calendar"
    // Ancho que pide la pestaña activa (lo usa la isla)
    readonly property real panelWidth: tab === "tasks" ? App.Config.tasks.panelWidth : App.Config.panel.productivityWidth

    implicitHeight: tabBar.height + 12 + calendar.implicitHeight

    function setTab(name) {
        if (name !== "calendar" && name !== "tasks")
            return false;
        if (name === tab)
            return true;
        reset();
        ST.SettingsStore.tasks.lastTab = name;
        focusTab();
        return true;
    }

    function nextTab() {
        setTab(tab === "calendar" ? "tasks" : "calendar");
    }

    function focusTab() {
        if (tab === "tasks")
            tasksLoader.item?.forceActiveFocus();
        else
            calendar.forceActiveFocus();
    }

    // Esc: true si cerró algo dentro del panel (menú, selector, evento desplegado, detalle…)
    function back() {
        if (tab === "tasks")
            return tasksLoader.item?.back() ?? false;
        return calendar.back();
    }

    function reset() {
        calendar.reset();
        tasksLoader.item?.reset();
    }

    onVisibleChanged: {
        if (visible)
            focusTab();
        else
            reset();
    }

    Keys.onPressed: event => {
        if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
            nextTab();
            event.accepted = true;
        }
    }

    Row {
        id: tabBar
        spacing: 4

        Repeater {
            model: root.tabs
            CC.Chip {
                required property var modelData
                height: 28
                radius: 14
                label: modelData.label
                selected: root.tab === modelData.id
                onClicked: root.setTab(modelData.id)
            }
        }
    }

    CalendarPanel {
        id: calendar
        y: tabBar.height + 12
        width: parent.width
        visible: root.tab === "calendar"
        onCloseRequested: root.closeRequested()
    }

    // La pestaña Tareas se crea la primera vez que se abre
    Loader {
        id: tasksLoader
        y: tabBar.height + 12
        width: parent.width
        height: calendar.implicitHeight
        active: root.tab === "tasks" || item !== null
        visible: root.tab === "tasks"
        sourceComponent: TK.TasksPanel {
            onCloseRequested: root.closeRequested()
        }
        onLoaded: if (root.tab === "tasks" && root.visible)
            item.forceActiveFocus()
    }
}
