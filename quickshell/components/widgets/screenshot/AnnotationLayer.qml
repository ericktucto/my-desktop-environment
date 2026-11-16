import QtQuick
import QtQuick.Shapes
import "../../../services/screenshot/" as S
import "../../../" as App

// El mouse del editor: crea, mueve y cambia de tamaño las anotaciones según la herramienta, y dibuja el marco y
// las manijas de la seleccionada. Las anotaciones mismas están en el lienzo del capturador (Annotation.qml).
// Con la herramienta Mover, apretar donde no hay ninguna deja pasar el clic al marco del área (la mueve).
Item {
    id: root

    // Área de la captura (en coordenadas de este item): solo ahí se empieza a dibujar
    property rect area: Qt.rect(0, 0, 0, 0)
    property bool active: false

    readonly property var store: S.AnnotationStore
    readonly property real handleRadius: 6
    readonly property real hitRadius: 11

    // ── Seleccionada: marco y manijas ──
    readonly property var row: {
        store.version;
        if (store.selectedId < 0)
            return null;
        const r = store.get(store.selectedId);
        return r ? {
            kind: r.kind,
            ax: r.ax,
            ay: r.ay,
            aw: r.aw,
            ah: r.ah,
            rot: r.rot
        } : null;
    }
    readonly property rect box: {
        store.version;
        return store.selectedId < 0 ? Qt.rect(0, 0, 0, 0) : store.bounds(store.selectedId);
    }

    function rotated(cx, cy, dx, dy, deg) {
        const a = deg * Math.PI / 180;
        return Qt.point(cx + dx * Math.cos(a) - dy * Math.sin(a), cy + dx * Math.sin(a) + dy * Math.cos(a));
    }

    // Las manijas: [{ id, x, y }]
    readonly property var handles: {
        const r = row;
        if (!r || store.editingId >= 0)
            return [];
        if (r.kind === "arrow" || r.kind === "line")
            return [
                {
                    id: "start",
                    x: r.ax,
                    y: r.ay
                },
                {
                    id: "end",
                    x: r.ax + r.aw,
                    y: r.ay + r.ah
                }
            ];
        if (r.kind === "rect" || r.kind === "ellipse" || r.kind === "pixel")
            return [
                {
                    id: "tl",
                    x: r.ax,
                    y: r.ay
                },
                {
                    id: "tr",
                    x: r.ax + r.aw,
                    y: r.ay
                },
                {
                    id: "bl",
                    x: r.ax,
                    y: r.ay + r.ah
                },
                {
                    id: "br",
                    x: r.ax + r.aw,
                    y: r.ay + r.ah
                }
            ];
        if (r.kind === "sticker") {
            const cx = r.ax + r.aw / 2, cy = r.ay + r.ah / 2;
            const out = [];
            for (const c of [["tl", -1, -1], ["tr", 1, -1], ["bl", -1, 1], ["br", 1, 1]]) {
                const p = rotated(cx, cy, c[1] * r.aw / 2, c[2] * r.ah / 2, r.rot);
                out.push({
                    id: c[0],
                    x: p.x,
                    y: p.y
                });
            }
            const g = rotated(cx, cy, 0, -(r.ah / 2 + 28), r.rot);
            out.push({
                id: "rotate",
                x: g.x,
                y: g.y
            });
            return out;
        }
        return [];
    }

    function handleAt(x, y) {
        for (const h of handles)
            if (Math.hypot(x - h.x, y - h.y) <= hitRadius)
                return h.id;
        return "";
    }

    // Marco punteado de la seleccionada
    Shape {
        visible: root.row !== null && root.store.editingId < 0 && root.row.kind !== "arrow" && root.row.kind !== "line"
        x: root.box.x
        y: root.box.y
        rotation: root.row && root.row.kind === "sticker" ? root.row.rot : 0
        transformOrigin: Item.Center
        width: root.box.width
        height: root.box.height
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: App.Theme.white
            strokeWidth: 1.5
            strokeStyle: ShapePath.DashLine
            dashPattern: [4, 3]
            fillColor: "transparent"
            startX: -4
            startY: -4
            PathLine {
                x: root.box.width + 4
                y: -4
            }
            PathLine {
                x: root.box.width + 4
                y: root.box.height + 4
            }
            PathLine {
                x: -4
                y: root.box.height + 4
            }
            PathLine {
                x: -4
                y: -4
            }
        }
    }
    Repeater {
        model: root.handles
        delegate: Rectangle {
            required property var modelData
            x: modelData.x - width / 2
            y: modelData.y - height / 2
            width: root.handleRadius * 2
            height: width
            radius: modelData.id === "rotate" ? width / 2 : 2
            color: modelData.id === "rotate" ? App.Theme.primary : App.Theme.white
            border.width: 1.5
            border.color: App.Theme.black
        }
    }

    // ── Mouse ──
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.active
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: cursorFor()

        // "" · "draw" · "move" · "start" | "end" | "tl" | "tr" | "bl" | "br" | "rotate"
        property string mode: ""
        property int target: -1
        property point press
        property var orig: null
        property real origDist: 1

        function inArea(x, y) {
            return x >= root.area.x && x <= root.area.x + root.area.width && y >= root.area.y && y <= root.area.y + root.area.height;
        }

        function cursorFor() {
            if (!containsMouse)
                return Qt.ArrowCursor;
            const t = root.store.tool;
            if (t === "move")
                return mode === "move" ? Qt.SizeAllCursor : Qt.ArrowCursor;
            if (t === "sticker")
                return Qt.ArrowCursor;
            return t === "text" ? Qt.IBeamCursor : Qt.CrossCursor;
        }

        function copyRow(aid) {
            const r = root.store.get(aid);
            return {
                kind: r.kind,
                ax: r.ax,
                ay: r.ay,
                aw: r.aw,
                ah: r.ah,
                rot: r.rot
            };
        }

        function clampX(x) {
            return Math.max(0, Math.min(root.width, x));
        }
        function clampY(y) {
            return Math.max(0, Math.min(root.height, y));
        }

        onPressed: function (e) {
            const st = root.store;
            if (st.editingId >= 0)
                st.endEdit();
            const x = e.x, y = e.y;
            press = Qt.point(x, y);
            mode = "";

            if (st.tool === "move") {
                const h = root.handleAt(x, y);
                if (h !== "" && st.selectedId >= 0) {
                    mode = h;
                    target = st.selectedId;
                    orig = copyRow(target);
                    const cx = orig.ax + orig.aw / 2, cy = orig.ay + orig.ah / 2;
                    origDist = Math.max(1, Math.hypot(x - cx, y - cy));
                    return;
                }
                const id = st.hitTest(x, y);
                if (id >= 0) {
                    st.selectedId = id;
                    mode = "move";
                    target = id;
                    orig = copyRow(id);
                    return;
                }
                st.selectedId = -1;
                e.accepted = false;
                return;
            }

            if (!inArea(x, y)) {
                e.accepted = false;
                return;
            }
            st.selectedId = -1;
            switch (st.tool) {
            case "text":
                st.beginEdit(st.add("text", {
                    ax: x,
                    ay: y
                }));
                return;
            case "counter":
                {
                    const d = st.sizeFor("counter");
                    st.add("counter", {
                        ax: x - d / 2,
                        ay: y - d / 2,
                        aw: d,
                        ah: d
                    });
                    st.commit();
                    return;
                }
            case "sticker":
                return;
            case "pen":
            case "marker":
                target = st.add(st.tool, {
                    ax: x,
                    ay: y
                });
                st.setPoints(target, [[0, 0]]);
                break;
            default:
                target = st.add(st.tool, {
                    ax: x,
                    ay: y
                });
            }
            mode = "draw";
        }

        onPositionChanged: function (e) {
            if (!pressed || mode === "")
                return;
            const st = root.store;
            const x = clampX(e.x), y = clampY(e.y);
            const shift = (e.modifiers & Qt.ShiftModifier) !== 0;

            if (mode === "move") {
                st.set(target, {
                    ax: orig.ax + (x - press.x),
                    ay: orig.ay + (y - press.y)
                });
                return;
            }
            if (mode === "rotate") {
                const cx = orig.ax + orig.aw / 2, cy = orig.ay + orig.ah / 2;
                let deg = Math.atan2(x - cx, -(y - cy)) * 180 / Math.PI;
                if (shift)
                    deg = Math.round(deg / 15) * 15;
                st.set(target, {
                    rot: deg
                });
                return;
            }
            if (mode === "start" || mode === "end") {
                // Los extremos de la flecha o la línea
                const ex = orig.ax + orig.aw, ey = orig.ay + orig.ah;
                if (mode === "start")
                    st.set(target, {
                        ax: x,
                        ay: y,
                        aw: ex - x,
                        ah: ey - y
                    });
                else
                    st.set(target, endpoint(orig.ax, orig.ay, x, y, shift));
                return;
            }
            if (mode === "tl" || mode === "tr" || mode === "bl" || mode === "br") {
                if (orig.kind === "sticker") {
                    // El sticker crece o se achica desde su centro, según qué tan lejos queda la manija
                    const cx = orig.ax + orig.aw / 2, cy = orig.ay + orig.ah / 2;
                    const k = Math.max(0.15, Math.hypot(x - cx, y - cy) / origDist);
                    const w = orig.aw * k, h = orig.ah * k;
                    st.set(target, {
                        ax: cx - w / 2,
                        ay: cy - h / 2,
                        aw: w,
                        ah: h
                    });
                } else {
                    const fx = mode.indexOf("l") >= 0 ? orig.ax + orig.aw : orig.ax;
                    const fy = mode.indexOf("t") >= 0 ? orig.ay + orig.ah : orig.ay;
                    st.set(target, boxFrom(fx, fy, x, y, shift));
                }
                return;
            }

            // Dibujando
            const r = st.get(target);
            if (!r)
                return;
            if (r.kind === "arrow" || r.kind === "line") {
                st.set(target, endpoint(r.ax, r.ay, x, y, shift));
            } else if (r.kind === "pen" || r.kind === "marker") {
                const p = st.pts[target];
                const last = p[p.length - 1];
                const dx = x - r.ax, dy = y - r.ay;
                if (Math.hypot(dx - last[0], dy - last[1]) >= 1.5) {
                    p.push([dx, dy]);
                    st.setPoints(target, p);
                }
            } else {
                st.set(target, boxFrom(press.x, press.y, x, y, shift));
            }
        }

        onReleased: function (e) {
            const st = root.store;
            if (mode === "") {
                return;
            }
            if (mode === "draw") {
                const r = st.get(target);
                const tiny = r && (r.kind === "arrow" || r.kind === "line" ? Math.hypot(r.aw, r.ah) < 4 : (r.kind === "pen" || r.kind === "marker" ? false : (r.aw < 4 || r.ah < 4)));
                if (!r || tiny)
                    st.remove(target);
                else
                    st.commit();
            } else {
                st.commit();
            }
            mode = "";
            target = -1;
        }

        onDoubleClicked: function (e) {
            const st = root.store;
            if (st.tool !== "move")
                return;
            const id = st.hitTest(e.x, e.y);
            if (id >= 0 && st.kindOf(id) === "text")
                st.beginEdit(id);
        }

        // Rectángulo de dos esquinas (con Shift, cuadrado)
        function boxFrom(x0, y0, x1, y1, square) {
            let w = x1 - x0, h = y1 - y0;
            if (square) {
                const s = Math.max(Math.abs(w), Math.abs(h));
                w = w < 0 ? -s : s;
                h = h < 0 ? -s : s;
            }
            return {
                ax: Math.min(x0, x0 + w),
                ay: Math.min(y0, y0 + h),
                aw: Math.abs(w),
                ah: Math.abs(h)
            };
        }

        // Extremo de una flecha o línea que sale de (x0, y0) (con Shift, a pasos de 45°)
        function endpoint(x0, y0, x1, y1, snap) {
            let dx = x1 - x0, dy = y1 - y0;
            if (snap) {
                const len = Math.hypot(dx, dy);
                const a = Math.round(Math.atan2(dy, dx) / (Math.PI / 4)) * (Math.PI / 4);
                dx = len * Math.cos(a);
                dy = len * Math.sin(a);
            }
            return {
                ax: x0,
                ay: y0,
                aw: dx,
                ah: dy
            };
        }
    }
}
