import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import "../../../services/screenshot/" as S
import "../../../" as App

// Una anotación (fila de AnnotationStore.list) dibujada según su tipo: flecha, línea, rectángulo, elipse, lápiz,
// resaltador, texto, número, pixelado o difuminado, y sticker. Las posiciones son las de la pantalla.
Item {
    id: root

    required property int aid
    required property string kind
    required property color col
    required property real sz
    required property real ax
    required property real ay
    required property real aw
    required property real ah
    required property string txt
    required property bool filled
    required property bool bg
    required property string emo
    required property string src
    required property real rot
    required property bool soft
    required property int rev

    // La imagen congelada (para pixelar o difuminar) y dónde está en pantalla
    property Item frozen: null
    property rect frozenRect: Qt.rect(0, 0, 0, 0)

    readonly property var conf: App.Config.screenshot
    readonly property bool editing: S.AnnotationStore.editingId === aid
    readonly property bool isShape: kind === "arrow" || kind === "line" || kind === "rect" || kind === "ellipse" || kind === "pen" || kind === "marker"
    // Negro sobre colores claros y blanco sobre oscuros (contorno y fondo del texto, número del círculo)
    readonly property bool dark: (col.r * 0.299 + col.g * 0.587 + col.b * 0.114) < 0.5
    readonly property color contrast: dark ? "#ffffff" : "#0a0a0f"

    x: ax
    y: ay
    width: kind === "arrow" || kind === "line" || kind === "pen" || kind === "marker" || kind === "text" ? 0 : aw
    height: kind === "arrow" || kind === "line" || kind === "pen" || kind === "marker" || kind === "text" ? 0 : ah
    rotation: kind === "sticker" ? rot : 0

    // ── Trazos y formas ──
    function pathText() {
        rev;
        switch (kind) {
        case "rect":
            return "M 0 0 H " + aw + " V " + ah + " H 0 Z";
        case "ellipse":
            {
                const rx = aw / 2, ry = ah / 2;
                return "M 0 " + ry + " A " + rx + " " + ry + " 0 1 1 " + aw + " " + ry + " A " + rx + " " + ry + " 0 1 1 0 " + ry + " Z";
            }
        case "line":
            return "M 0 0 L " + aw + " " + ah;
        case "arrow":
            {
                const len = Math.hypot(aw, ah);
                if (len < 1)
                    return "M 0 0";
                const ux = aw / len, uy = ah / len;
                const head = Math.min(len, 10 + sz * 3);
                const bx = aw - ux * head, by = ah - uy * head;
                const hw = head * 0.45;
                return "M 0 0 L " + bx + " " + by + " M " + aw + " " + ah + " L " + (bx - uy * hw) + " " + (by + ux * hw) + " L " + (bx + uy * hw) + " " + (by - ux * hw) + " Z";
            }
        case "pen":
        case "marker":
            {
                const p = S.AnnotationStore.pts[aid] || [];
                if (p.length === 0)
                    return "M 0 0";
                let d = "M " + p[0][0] + " " + p[0][1];
                if (p.length === 1)
                    return d + " L " + (p[0][0] + 0.01) + " " + p[0][1];
                for (let i = 1; i < p.length; i++)
                    d += " L " + p[i][0] + " " + p[i][1];
                return d;
            }
        }
        return "M 0 0";
    }

    Shape {
        visible: root.isShape
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.kind === "marker" ? Qt.rgba(root.col.r, root.col.g, root.col.b, root.conf.highlighterOpacity) : root.col
            strokeWidth: root.kind === "marker" ? root.sz * 4 : root.sz
            fillColor: root.kind === "arrow" || ((root.kind === "rect" || root.kind === "ellipse") && root.filled) ? root.col : "transparent"
            capStyle: root.kind === "marker" ? ShapePath.FlatCap : ShapePath.RoundCap
            joinStyle: root.kind === "rect" ? ShapePath.MiterJoin : ShapePath.RoundJoin

            PathSvg {
                path: root.pathText()
            }
        }
    }

    // ── Texto ──
    Item {
        id: textBox
        visible: root.kind === "text"
        readonly property Item field: root.editing ? edit : label
        width: Math.max(field.implicitWidth, root.sz * 0.5)
        height: field.implicitHeight

        // Solo el texto mide su tamaño (los demás tipos ya traen el suyo)
        onWidthChanged: if (root.kind === "text")
            S.AnnotationStore.measure(root.aid, width, height)
        onHeightChanged: if (root.kind === "text")
            S.AnnotationStore.measure(root.aid, width, height)

        Rectangle {
            visible: root.bg
            x: -6
            y: -3
            width: parent.width + 12
            height: parent.height + 6
            radius: 6
            color: root.contrast
        }
        Text {
            id: label
            visible: !root.editing
            text: root.txt
            color: root.col
            style: root.bg ? Text.Normal : Text.Outline
            styleColor: root.contrast
            font.family: App.Config.fonts.text
            font.pixelSize: root.sz
            font.weight: Font.Bold
        }
        TextEdit {
            id: edit
            visible: root.editing
            text: root.txt
            color: root.col
            selectionColor: App.Theme.primary
            font.family: App.Config.fonts.text
            font.pixelSize: root.sz
            font.weight: Font.Bold
            cursorDelegate: Rectangle {
                width: 2
                color: root.col
            }
            onTextChanged: if (root.editing)
                S.AnnotationStore.set(root.aid, {
                    txt: text
                })
            Keys.onEscapePressed: S.AnnotationStore.endEdit()
            Keys.onPressed: function (e) {
                // Ctrl+Enter termina; Enter solo baja de línea
                if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && (e.modifiers & Qt.ControlModifier)) {
                    S.AnnotationStore.endEdit();
                    e.accepted = true;
                }
            }
        }
    }
    onEditingChanged: {
        if (editing) {
            edit.text = txt;
            edit.forceActiveFocus();
            edit.cursorPosition = edit.length;
        }
    }

    // ── Número ──
    Rectangle {
        visible: root.kind === "counter"
        width: root.aw
        height: root.ah
        radius: width / 2
        color: root.col
        border.width: 2
        border.color: root.contrast

        Text {
            anchors.centerIn: parent
            text: root.kind === "counter" ? S.AnnotationStore.counterNumber(root.aid) : ""
            color: root.contrast
            font.family: App.Config.fonts.text
            font.pixelSize: root.sz * 0.55
            font.weight: Font.Bold
        }
    }

    // ── Pixelar o difuminar: la imagen congelada bajo el área, sin las demás anotaciones ──
    Item {
        id: pixel
        visible: root.kind === "pixel" && root.frozen !== null
        width: root.aw
        height: root.ah
        clip: true

        readonly property real pad: root.conf.blurRadius / 2

        // Pixelado: la región en una textura chica, ampliada sin suavizar (bloques)
        ShaderEffectSource {
            visible: !root.soft
            anchors.fill: parent
            sourceItem: root.frozen
            sourceRect: Qt.rect(root.ax - root.frozenRect.x, root.ay - root.frozenRect.y, Math.max(1, root.aw), Math.max(1, root.ah))
            textureSize: Qt.size(Math.max(1, Math.round(root.aw / root.conf.pixelBlock)), Math.max(1, Math.round(root.ah / root.conf.pixelBlock)))
            smooth: false
            live: true
        }

        // Difuminado: la región con un margen, para que los bordes no queden claros
        ShaderEffectSource {
            id: blurSource
            visible: false
            x: -pixel.pad
            y: -pixel.pad
            width: root.aw + 2 * pixel.pad
            height: root.ah + 2 * pixel.pad
            sourceItem: root.frozen
            sourceRect: Qt.rect(root.ax - root.frozenRect.x - pixel.pad, root.ay - root.frozenRect.y - pixel.pad, Math.max(1, root.aw + 2 * pixel.pad), Math.max(1, root.ah + 2 * pixel.pad))
            live: true
        }
        MultiEffect {
            visible: root.soft
            x: -pixel.pad
            y: -pixel.pad
            width: blurSource.width
            height: blurSource.height
            source: blurSource
            blurEnabled: true
            blurMax: root.conf.blurRadius
            blur: 1.0
        }
    }

    // ── Sticker ──
    Item {
        visible: root.kind === "sticker"
        width: root.aw
        height: root.ah

        // El emoji se dibuja grande y se reduce: así queda suave al girarlo y al cambiarle el tamaño
        Text {
            visible: root.emo !== ""
            anchors.centerIn: parent
            text: root.emo
            font.pixelSize: 128
            scale: Math.max(8, Math.min(root.aw, root.ah) * 0.78) / 128
            layer.enabled: true
            layer.smooth: true
            layer.mipmap: true
        }
        Image {
            visible: root.src !== ""
            anchors.fill: parent
            source: root.src
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(Math.max(1, root.aw * 2), Math.max(1, root.ah * 2))
            smooth: true
            mipmap: true
        }
    }
}
