import QtQuick
import "../../../" as App

// Marco de una región de la pantalla: oscurece todo menos el área `sel`, y dibuja su borde, sus esquinas y
// su medida. Con `interactive` se arrastra para marcar el área, y se puede mover o cambiar de tamaño desde
// los bordes y las esquinas. Lo usan el selector del grabador (RegionSelector) y el capturador (ScreenshotOverlay).
Item {
    id: root

    // Área elegida, en coordenadas de este item
    property rect sel: Qt.rect(0, 0, 0, 0)
    readonly property real minSize: 8
    readonly property bool has: sel.width >= minSize && sel.height >= minSize
    readonly property real handle: 10

    // false: no atiende el mouse (otra capa lo maneja y mueve `sel` ella misma)
    property bool interactive: true
    // false: solo el oscurecido y el borde (sin esquinas ni medida)
    property bool showHandles: true
    property bool showSize: true
    property string hint: "Arrastra para elegir el área"
    property real dimOpacity: 0.55

    // El mouse está apretado marcando, moviendo o cambiando el tamaño
    readonly property bool dragging: drag.pressed
    // Soltó el mouse con un área válida tras marcarla, moverla o cambiarle el tamaño
    signal released
    // Apretó el mouse fuera del área: empieza una nueva
    signal started

    // ── Oscurecido: todo menos el área elegida ──
    readonly property color dim: Qt.rgba(0, 0, 0, dimOpacity)
    Rectangle {
        visible: !root.has
        anchors.fill: parent
        color: root.dim
    }
    Rectangle {
        visible: root.has
        x: 0
        y: 0
        width: parent.width
        height: root.sel.y
        color: root.dim
    }
    Rectangle {
        visible: root.has
        x: 0
        y: root.sel.y + root.sel.height
        width: parent.width
        height: parent.height - y
        color: root.dim
    }
    Rectangle {
        visible: root.has
        x: 0
        y: root.sel.y
        width: root.sel.x
        height: root.sel.height
        color: root.dim
    }
    Rectangle {
        visible: root.has
        x: root.sel.x + root.sel.width
        y: root.sel.y
        width: parent.width - x
        height: root.sel.height
        color: root.dim
    }

    Text {
        visible: !root.has && root.hint !== ""
        anchors.centerIn: parent
        text: root.hint
        color: App.Theme.white
        opacity: 0.85
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.lg
        font.weight: Font.Medium
    }

    // ── Borde, esquinas y medidas ──
    Rectangle {
        visible: root.has
        x: root.sel.x
        y: root.sel.y
        width: root.sel.width
        height: root.sel.height
        color: "transparent"
        border.width: 2
        border.color: App.Theme.white
    }
    Repeater {
        model: root.has && root.showHandles ? [[0, 0], [0.5, 0], [1, 0], [0, 0.5], [1, 0.5], [0, 1], [0.5, 1], [1, 1]] : []
        delegate: Rectangle {
            required property var modelData
            width: root.handle
            height: root.handle
            radius: 2
            color: App.Theme.white
            x: root.sel.x + root.sel.width * modelData[0] - width / 2
            y: root.sel.y + root.sel.height * modelData[1] - height / 2
        }
    }
    Rectangle {
        visible: root.has && root.showSize
        x: Math.max(0, Math.min(parent.width - width, root.sel.x))
        y: root.sel.y > height + 8 ? root.sel.y - height - 8 : root.sel.y + 8
        width: sizeText.implicitWidth + 20
        height: 26
        radius: height / 2
        color: App.Theme.island

        Text {
            id: sizeText
            anchors.centerIn: parent
            text: Math.round(root.sel.width) + " × " + Math.round(root.sel.height)
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.DemiBold
        }
    }

    // ── Arrastre: marcar, mover y cambiar de tamaño ──
    MouseArea {
        id: drag
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: root.interactive ? cursorFor(hover) : Qt.ArrowCursor

        property string hover: ""
        property string mode: ""
        property point press
        property rect orig

        // "" fuera del área · "move" dentro · combinación de t, b, l, r en un borde o esquina
        function hit(mx, my) {
            if (!root.has)
                return "";
            const m = 12;
            const s = root.sel;
            if (mx < s.x - m || mx > s.x + s.width + m || my < s.y - m || my > s.y + s.height + m)
                return "";
            let f = "";
            if (Math.abs(my - s.y) <= m)
                f += "t";
            else if (Math.abs(my - (s.y + s.height)) <= m)
                f += "b";
            if (Math.abs(mx - s.x) <= m)
                f += "l";
            else if (Math.abs(mx - (s.x + s.width)) <= m)
                f += "r";
            return f === "" ? "move" : f;
        }

        function cursorFor(h) {
            switch (h) {
            case "t":
            case "b":
                return Qt.SizeVerCursor;
            case "l":
            case "r":
                return Qt.SizeHorCursor;
            case "tl":
            case "br":
                return Qt.SizeFDiagCursor;
            case "tr":
            case "bl":
                return Qt.SizeBDiagCursor;
            case "move":
                return Qt.SizeAllCursor;
            default:
                return Qt.CrossCursor;
            }
        }

        function clamp(v, lo, hi) {
            return Math.max(lo, Math.min(hi, v));
        }

        // Mouse en (x, y) con el botón apretado: marca, mueve o cambia de tamaño según `mode`
        function dragTo(x, y) {
            const W = root.width;
            const H = root.height;
            const mx = clamp(x, 0, W);
            const my = clamp(y, 0, H);
            if (mode === "move") {
                const nx = clamp(orig.x + (x - press.x), 0, W - orig.width);
                const ny = clamp(orig.y + (y - press.y), 0, H - orig.height);
                root.sel = Qt.rect(nx, ny, orig.width, orig.height);
                return;
            }
            // Esquinas fijas del rectángulo; la que se arrastra sigue al mouse (y se normaliza si se cruza)
            let x0 = orig.x, x1 = orig.x + orig.width, y0 = orig.y, y1 = orig.y + orig.height;
            if (mode === "new") {
                x0 = press.x;
                y0 = press.y;
                x1 = mx;
                y1 = my;
            } else {
                if (mode.indexOf("l") >= 0)
                    x0 = mx;
                if (mode.indexOf("r") >= 0)
                    x1 = mx;
                if (mode.indexOf("t") >= 0)
                    y0 = my;
                if (mode.indexOf("b") >= 0)
                    y1 = my;
            }
            root.sel = Qt.rect(Math.min(x0, x1), Math.min(y0, y1), Math.abs(x1 - x0), Math.abs(y1 - y0));
        }

        function pressAt(x, y) {
            root.forceActiveFocus();
            press = Qt.point(x, y);
            orig = root.sel;
            mode = hit(x, y) || "new";
            if (mode === "new") {
                root.sel = Qt.rect(x, y, 0, 0);
                root.started();
            }
        }

        function releaseAt(x, y) {
            hover = hit(x, y);
            // Un clic suelto no deja un área diminuta
            if (!root.has)
                root.sel = Qt.rect(0, 0, 0, 0);
            else
                root.released();
        }

        onPositionChanged: function (e) {
            if (pressed)
                dragTo(e.x, e.y);
            else
                hover = hit(e.x, e.y);
        }
        onPressed: function (e) {
            pressAt(e.x, e.y);
        }
        onReleased: function (e) {
            releaseAt(e.x, e.y);
        }
    }
}
