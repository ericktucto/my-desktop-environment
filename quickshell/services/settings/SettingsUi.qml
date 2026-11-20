pragma Singleton
import QtQuick
import Quickshell.Io

// Estado de la ventana de Preferencias del sistema: abierta o no, página actual, búsqueda y la fila que
// parpadea tras elegir un resultado. Las filas de cada página se registran aquí (para el buscador).
Singleton {
    id: ui

    property bool open: false
    // id de la página mostrada (ver components/settings/pages.js)
    property string page: "appearance"
    property string query: ""
    // searchId de la fila que parpadea (vacío = ninguna)
    property string highlight: ""

    // Filas registradas: { page, id, label, hint, keywords }
    property var registry: []

    function register(entry) {
        // (se reasigna el arreglo entero para que los resultados se vuelvan a calcular)
        registry = registry.filter(e => !(e.page === entry.page && e.id === entry.id)).concat([entry]);
    }

    function unregister(page, id) {
        registry = registry.filter(e => !(e.page === page && e.id === id));
    }

    // Texto sin acentos y en minúscula
    function norm(s) {
        return String(s || "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
    }

    // Filas que coinciden con la búsqueda (todas las palabras); vacío sin búsqueda
    readonly property var results: {
        const q = norm(query).split(/\s+/).filter(w => w !== "");
        if (q.length === 0)
            return [];
        return registry.filter(e => {
            const hay = norm(e.label + " " + (e.hint ?? "") + " " + (e.keywords ?? "") + " " + (e.pageName ?? ""));
            return q.every(w => hay.includes(w));
        }).slice(0, 40);
    }

    // Va a una fila: abre su página y la hace parpadear
    function goTo(pageId, rowId) {
        page = pageId;
        query = "";
        highlight = rowId ?? "";
        open = true;
        highlightTimer.restart();
    }

    function show(pageId) {
        if (pageId)
            page = pageId;
        query = "";
        highlight = "";
        open = true;
    }

    Timer {
        id: highlightTimer
        interval: 1800
        onTriggered: ui.highlight = ""
    }

    // qs ipc call stixshell@settings open [página] · toggle · close
    IpcHandler {
        target: "stixshell@settings"
        function open(page: string): void {
            ui.show(page);
        }
        function toggle(): void {
            if (ui.open)
                ui.open = false;
            else
                ui.show("");
        }
        function close(): void {
            ui.open = false;
        }
    }
}
