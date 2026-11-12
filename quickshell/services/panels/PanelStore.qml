pragma Singleton
import QtQuick
import Quickshell

// Registro de las pills que tienen panel (Island con body).
// Cada Island se registra sola; shell.qml solo pregunta si hay alguna abierta.
Singleton {
    id: root

    property var items: []
    // `p &&`: por si una pill se destruyó
    readonly property bool anyExpanded: items.some(p => p && p.expanded)

    function add(p) {
        if (!items.includes(p))
            items = items.concat([p]);
    }

    function remove(p) {
        if (items.includes(p))
            items = items.filter(x => x !== p);
    }

    function closeOthers(except) {
        items.forEach(p => {
            if (p && p !== except && p.expanded)
                p.expanded = false;
        });
    }

    // Esc: si la isla abierta sabe volver atrás (escapeBack), lo hace; si no, se cierra todo
    function escapePressed() {
        const open = items.filter(p => p && p.expanded);
        for (const p of open)
            if (p.escapeBack && p.escapeBack())
                return;
        closeAll();
    }

    function closeAll() {
        items.forEach(p => {
            if (p && p.expanded)
                p.expanded = false;
        });
    }
}
