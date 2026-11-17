import QtQuick
import "../../../services/calendar/" as CS
import "../../../" as App

// Pestaña Calendario: cabecera, la vista (Mes o por horas) y la lista de eventos del día elegido.
// Teclado: ←/→ cambian el período, T vuelve a hoy, M/S/3/D cambian la vista.
Item {
    id: root

    readonly property var store: CS.CalendarStore
    readonly property var cfg: App.Config.calendar

    signal closeRequested

    implicitHeight: header.height + 14 + cfg.viewHeight + 12 + 1 + 12 + cfg.listHeight
    focus: true

    // Esc: primero el menú, luego el selector de mes, luego el evento desplegado; true si cerró algo
    function back() {
        if (header.menuOpen) {
            header.menuOpen = false;
            return true;
        }
        if (store.pickerOpen) {
            store.pickerOpen = false;
            return true;
        }
        return list.collapse();
    }

    function reset() {
        header.menuOpen = false;
        store.pickerOpen = false;
    }

    Keys.onPressed: event => {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            return;
        let used = true;
        if (event.key === Qt.Key_Left)
            store.shift(-1);
        else if (event.key === Qt.Key_Right)
            store.shift(1);
        else if (event.key === Qt.Key_T)
            store.goToday();
        else if (event.key === Qt.Key_M)
            store.setView("month");
        else if (event.key === Qt.Key_S)
            store.setView("week");
        else if (event.key === Qt.Key_3)
            store.setView("days3");
        else if (event.key === Qt.Key_D)
            store.setView("day");
        else
            used = false;
        event.accepted = used;
    }

    CalendarHeader {
        id: header
        z: 10
        width: parent.width
    }

    // Un clic fuera del menú ⋮ lo cierra
    MouseArea {
        anchors.fill: parent
        z: 9
        visible: header.menuOpen
        onClicked: header.menuOpen = false
    }

    Item {
        id: viewArea
        y: header.height + 14
        width: parent.width
        height: root.cfg.viewHeight

        MonthView {
            anchors.fill: parent
            visible: root.store.view === "month"
        }
        TimeGridView {
            anchors.fill: parent
            visible: root.store.view !== "month"
            onCloseRequested: root.closeRequested()
        }
        MonthPicker {
            anchors.fill: parent
            visible: root.store.pickerOpen
            z: 5
        }
    }

    Rectangle {
        id: line
        y: viewArea.y + viewArea.height + 12
        width: parent.width
        height: 1
        color: App.Theme.islandEdge
    }

    EventList {
        id: list
        y: line.y + 13
        width: parent.width
        height: root.cfg.listHeight
        onCloseRequested: root.closeRequested()
    }
}
