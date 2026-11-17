import QtQuick
import "../../../../services/tasks/Dates.js" as Dates
import "../../../../" as App

// Vista Hechas: el historial por día (lo más reciente arriba) con un resumen. Para reabrir una tarea:
// x, Espacio o el círculo. `/` busca dentro del historial.
Item {
    id: root

    property var groups: []
    property string selectedId: ""
    property string emptyText: "Aún no hay tareas hechas"
    property string todayKey: ""

    signal taskClicked(string id)
    signal taskToggled(string id)
    signal taskOpened(string id)

    function ensureVisible(id) {
        list.ensureVisible(id);
    }

    function positionViewAtBeginning() {
        list.positionViewAtBeginning();
    }

    // Hechas hoy y en los últimos 7 días (no cuenta las canceladas)
    readonly property string summary: {
        if (!Dates.isKey(todayKey))
            return "";
        const from = Dates.addDays(todayKey, -6);
        let today = 0;
        let week = 0;
        for (const g of groups)
            for (const t of g.tasks) {
                if (t.status !== "done")
                    continue;
                if (g.key === todayKey)
                    today++;
                if (Dates.inRange(g.key, from, todayKey))
                    week++;
            }
        return today + " hoy · " + week + " en los últimos 7 días";
    }

    Text {
        id: summaryText
        visible: root.groups.length > 0
        x: 10
        height: 22
        verticalAlignment: Text.AlignVCenter
        text: root.summary
        color: App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
    }

    TaskList {
        id: list
        y: summaryText.visible ? 24 : 0
        width: parent.width
        height: parent.height - y
        groups: root.groups
        selectedId: root.selectedId
        showHeaders: true
        emptyText: root.emptyText
        onTaskClicked: id => root.taskClicked(id)
        onTaskToggled: id => root.taskToggled(id)
        onTaskOpened: id => root.taskOpened(id)
    }
}
