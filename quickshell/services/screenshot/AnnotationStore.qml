pragma Singleton
import QtQuick
import Quickshell
import "../settings/" as ST
import "../../" as App

// Anotaciones del capturador (components/widgets/screenshot): lo que se dibuja sobre la captura.
//
// Cada anotación es una fila de `list` (un ListModel, así mover o cambiar una no recrea las demás):
//   aid      identificador (no cambia nunca)
//   kind     arrow | line | rect | ellipse | pen | marker | text | counter | pixel | sticker
//   col      color "#rrggbb"
//   sz       grosor del trazo, tamaño del texto o del número
//   ax, ay   posición en la pantalla (arrow y line: el inicio; pen y marker: el origen de sus puntos)
//   aw, ah   tamaño (arrow y line: hacia dónde va el final, con signo; text: lo mide el texto)
//   txt      texto
//   filled   rect y ellipse rellenos
//   bg       text con fondo
//   emo      emoji del sticker
//   src      PNG o SVG del sticker
//   rot      giro en grados (sticker)
//   soft     pixel: difuminar en vez de pixelar
//   rev      sube cada vez que cambia algo (para repintar los trazos)
// Los puntos de pen y marker están en `pts[aid]`, relativos a (ax, ay).
//
// La herramienta, el color y el grosor salen de settings.json (screenshot) y se recuerdan.
Singleton {
    id: store

    readonly property var cfg: ST.SettingsStore.screenshot
    readonly property var conf: App.Config.screenshot

    readonly property ListModel list: ListModel {
        id: items
    }
    readonly property int count: items.count
    property var pts: ({})
    property int nextId: 1
    // Sube con cualquier cambio (para recalcular marcos y manijas de la seleccionada)
    property int version: 0
    // Sube al sumar o quitar (los números 1, 2, 3… se recalculan)
    property int order: 0
    Connections {
        target: items
        function onCountChanged() {
            store.order++;
        }
    }

    // ── Herramienta, color y grosor ──
    readonly property string tool: cfg.tool
    readonly property string colorHex: conf.colors[Math.max(0, Math.min(conf.colors.length - 1, cfg.color))]
    readonly property int sizeIndex: Math.max(0, Math.min(2, cfg.size))

    property int selectedId: -1
    property int editingId: -1
    readonly property bool hasSelection: selectedId >= 0

    function setTool(t) {
        endEdit();
        cfg.tool = t;
        // Con otra herramienta no queda nada seleccionado (salvo al mover)
        if (t !== "move")
            selectedId = -1;
    }

    function sizeFor(kind) {
        if (kind === "text")
            return conf.textSizes[sizeIndex];
        if (kind === "counter")
            return conf.counterSizes[sizeIndex];
        if (kind === "sticker")
            return conf.stickerSize;
        return conf.strokes[sizeIndex];
    }

    // Lo que se cambia en la barra también cambia la anotación seleccionada
    function setColor(i) {
        cfg.color = i;
        if (selectedId >= 0 && kindOf(selectedId) !== "pixel" && kindOf(selectedId) !== "sticker") {
            set(selectedId, {
                col: conf.colors[i]
            });
            commit();
        }
    }
    function setSize(i) {
        cfg.size = i;
        const k = kindOf(selectedId);
        if (k !== "" && k !== "pixel" && k !== "sticker") {
            set(selectedId, {
                sz: sizeFor(k)
            });
            commit();
        }
    }
    function toggleFill() {
        cfg.fill = !cfg.fill;
        const k = kindOf(selectedId);
        if (k === "rect" || k === "ellipse") {
            set(selectedId, {
                filled: cfg.fill
            });
            commit();
        }
    }
    function toggleTextBackground() {
        cfg.textBackground = !cfg.textBackground;
        if (kindOf(selectedId) === "text") {
            set(selectedId, {
                bg: cfg.textBackground
            });
            commit();
        }
    }
    function toggleBlur() {
        cfg.blur = !cfg.blur;
        if (kindOf(selectedId) === "pixel") {
            set(selectedId, {
                soft: cfg.blur
            });
            commit();
        }
    }

    // ── Filas ──
    function indexOf(aid) {
        for (let i = 0; i < items.count; i++)
            if (items.get(i).aid === aid)
                return i;
        return -1;
    }

    function kindOf(aid) {
        const i = indexOf(aid);
        return i < 0 ? "" : items.get(i).kind;
    }

    function get(aid) {
        const i = indexOf(aid);
        return i < 0 ? null : items.get(i);
    }

    // Una fila nueva (no se guarda en el historial hasta `commit`)
    function add(kind, props) {
        const row = {
            aid: nextId++,
            kind: kind,
            col: colorHex,
            sz: sizeFor(kind),
            ax: 0,
            ay: 0,
            aw: 0,
            ah: 0,
            txt: "",
            filled: kind === "rect" || kind === "ellipse" ? cfg.fill : false,
            bg: kind === "text" ? cfg.textBackground : false,
            emo: "",
            src: "",
            rot: 0,
            soft: kind === "pixel" ? cfg.blur : false,
            rev: 0
        };
        for (const k in props)
            row[k] = props[k];
        items.append(row);
        version++;
        return row.aid;
    }

    function set(aid, props) {
        const i = indexOf(aid);
        if (i < 0)
            return;
        for (const k in props)
            items.setProperty(i, k, props[k]);
        items.setProperty(i, "rev", items.get(i).rev + 1);
        version++;
    }

    function remove(aid) {
        const i = indexOf(aid);
        if (i < 0)
            return;
        items.remove(i);
        version++;
        delete pts[aid];
        if (selectedId === aid)
            selectedId = -1;
        if (editingId === aid)
            editingId = -1;
    }

    function removeSelected() {
        if (selectedId < 0)
            return;
        remove(selectedId);
        commit();
    }

    function setPoints(aid, list) {
        pts[aid] = list;
        const i = indexOf(aid);
        if (i >= 0)
            items.setProperty(i, "rev", items.get(i).rev + 1);
        version++;
    }

    // Número del círculo 1, 2, 3…: su orden entre los círculos
    function counterNumber(aid) {
        order;
        let n = 0;
        for (let i = 0; i < items.count; i++) {
            const r = items.get(i);
            if (r.kind === "counter")
                n++;
            if (r.aid === aid)
                return n;
        }
        return n;
    }

    // ── Texto ──
    function beginEdit(aid) {
        selectedId = aid;
        editingId = aid;
    }

    // Termina de escribir: un texto vacío no queda
    function endEdit() {
        if (editingId < 0)
            return;
        const aid = editingId;
        editingId = -1;
        const r = get(aid);
        if (r && r.txt.trim() === "") {
            remove(aid);
            selectedId = -1;
        }
        commit();
    }

    // ── Geometría (para elegir con el mouse) ──
    function bounds(aid) {
        const r = get(aid);
        if (!r)
            return Qt.rect(0, 0, 0, 0);
        if (r.kind === "arrow" || r.kind === "line") {
            const x0 = Math.min(r.ax, r.ax + r.aw), y0 = Math.min(r.ay, r.ay + r.ah);
            return Qt.rect(x0, y0, Math.abs(r.aw), Math.abs(r.ah));
        }
        if (r.kind === "pen" || r.kind === "marker") {
            const p = pts[aid] || [];
            if (p.length === 0)
                return Qt.rect(r.ax, r.ay, 0, 0);
            let x0 = p[0][0], x1 = p[0][0], y0 = p[0][1], y1 = p[0][1];
            for (const q of p) {
                x0 = Math.min(x0, q[0]);
                x1 = Math.max(x1, q[0]);
                y0 = Math.min(y0, q[1]);
                y1 = Math.max(y1, q[1]);
            }
            return Qt.rect(r.ax + x0, r.ay + y0, x1 - x0, y1 - y0);
        }
        return Qt.rect(r.ax, r.ay, r.aw, r.ah);
    }

    function segmentDistance(px, py, x0, y0, x1, y1) {
        const dx = x1 - x0, dy = y1 - y0;
        const len2 = dx * dx + dy * dy;
        let t = len2 === 0 ? 0 : ((px - x0) * dx + (py - y0) * dy) / len2;
        t = Math.max(0, Math.min(1, t));
        return Math.hypot(px - (x0 + t * dx), py - (y0 + t * dy));
    }

    function hits(aid, x, y) {
        const r = get(aid);
        if (!r)
            return false;
        if (r.kind === "arrow" || r.kind === "line")
            return segmentDistance(x, y, r.ax, r.ay, r.ax + r.aw, r.ay + r.ah) <= Math.max(8, r.sz + 4);
        if (r.kind === "pen" || r.kind === "marker") {
            const p = pts[aid] || [];
            const reach = Math.max(8, (r.kind === "marker" ? r.sz * 4 : r.sz) / 2 + 6);
            if (p.length === 1)
                return Math.hypot(x - r.ax - p[0][0], y - r.ay - p[0][1]) <= reach;
            for (let i = 1; i < p.length; i++)
                if (segmentDistance(x, y, r.ax + p[i - 1][0], r.ay + p[i - 1][1], r.ax + p[i][0], r.ay + p[i][1]) <= reach)
                    return true;
            return false;
        }
        let px = x, py = y;
        if (r.rot !== 0) {
            // El punto se lleva al sistema del sticker sin girar
            const cx = r.ax + r.aw / 2, cy = r.ay + r.ah / 2;
            const a = -r.rot * Math.PI / 180;
            const dx = x - cx, dy = y - cy;
            px = cx + dx * Math.cos(a) - dy * Math.sin(a);
            py = cy + dx * Math.sin(a) + dy * Math.cos(a);
        }
        const m = 4;
        return px >= r.ax - m && px <= r.ax + r.aw + m && py >= r.ay - m && py <= r.ay + r.ah + m;
    }

    // La de más arriba bajo (x, y), o -1
    function hitTest(x, y) {
        for (let i = items.count - 1; i >= 0; i--)
            if (hits(items.get(i).aid, x, y))
                return items.get(i).aid;
        return -1;
    }

    function moveBy(aid, dx, dy) {
        const r = get(aid);
        if (r)
            set(aid, {
                ax: r.ax + dx,
                ay: r.ay + dy
            });
    }

    // El texto mide su propio tamaño (sin historial ni repintado)
    function measure(aid, w, h) {
        const i = indexOf(aid);
        if (i < 0)
            return;
        const r = items.get(i);
        if (Math.abs(r.aw - w) > 0.5)
            items.setProperty(i, "aw", w);
        if (Math.abs(r.ah - h) > 0.5)
            items.setProperty(i, "ah", h);
        version++;
    }

    // ── Historial ──
    property var history: []
    property int histPos: -1
    readonly property bool canUndo: histPos > 0
    readonly property bool canRedo: histPos < history.length - 1

    function snapshot() {
        const rows = [];
        for (let i = 0; i < items.count; i++) {
            const r = items.get(i);
            const o = {};
            for (const k of ["aid", "kind", "col", "sz", "ax", "ay", "aw", "ah", "txt", "filled", "bg", "emo", "src", "rot", "soft", "rev"])
                o[k] = r[k];
            rows.push(o);
        }
        return JSON.stringify({
            rows: rows,
            pts: pts
        });
    }

    // Un paso nuevo en el historial (se pierde lo que se podía rehacer)
    function commit() {
        const s = snapshot();
        if (histPos >= 0 && history[histPos] === s)
            return;
        const h = history.slice(0, histPos + 1);
        h.push(s);
        while (h.length > conf.historyMax)
            h.shift();
        history = h;
        histPos = h.length - 1;
    }

    function restore(s) {
        const d = JSON.parse(s);
        items.clear();
        for (const r of d.rows)
            items.append(r);
        pts = d.pts;
        selectedId = -1;
        editingId = -1;
        version++;
    }

    function undo() {
        endEdit();
        if (!canUndo)
            return;
        histPos--;
        restore(history[histPos]);
    }

    function redo() {
        if (!canRedo)
            return;
        histPos++;
        restore(history[histPos]);
    }

    // Todo de nuevo (al abrir o cerrar el capturador)
    function reset() {
        items.clear();
        pts = {};
        selectedId = -1;
        editingId = -1;
        history = [];
        histPos = -1;
        commit();
    }

    Component.onCompleted: reset()
}
