import QtQuick
import Quickshell
import Quickshell.Wayland
import "../region/" as R
import "../../../services/screenshot/" as S
import "../../../" as App

// El capturador: una ventana a pantalla completa por monitor con la pantalla congelada (la tomó grim al abrir).
// Sobre ella: el marco de la región (RegionFrame), el lienzo con las anotaciones, la barra de herramientas del
// editor, el panel de stickers y la barra de modos. Lo que se exporta es el lienzo recortado al área.
Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: win

        required property var modelData
        screen: modelData

        readonly property var store: S.ScreenshotStore
        readonly property var notes: S.AnnotationStore
        readonly property var conf: App.Config.screenshot
        // Volver a editar una imagen guardada: solo en el monitor enfocado
        readonly property bool editMode: store.editSource !== ""
        readonly property bool isBar: store.barScreen === modelData.name

        visible: store.shown && !store.filePicking && (!editMode || isBar)

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "stixshell-screenshot"
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Item {
            id: root
            anchors.fill: parent
            focus: true

            readonly property string name: win.modelData.name
            readonly property string mode: win.store.mode
            readonly property bool editorOn: win.store.editorOn
            readonly property string framePath: win.editMode ? win.store.editSource : (win.store.frames[name] ?? "")
            // El área ya quedó fijada y se anota sobre ella (solo con el Editor)
            property bool chosen: false
            // Esc avisó que se perdería lo anotado
            property bool armed: false
            // Ventana bajo el mouse (modo Ventana)
            property var hoverWin: null

            // Dónde está la imagen: toda la pantalla, o centrada y reducida si es una imagen guardada
            readonly property rect imageRect: {
                if (!win.editMode)
                    return Qt.rect(0, 0, width, height);
                const iw = shot.implicitWidth, ih = shot.implicitHeight;
                if (iw <= 0 || ih <= 0)
                    return Qt.rect(0, 0, 0, 0);
                const s = Math.min(1, (width - 80) / iw, (height - 260) / ih);
                const w = Math.round(iw * s), h = Math.round(ih * s);
                return Qt.rect(Math.round((width - w) / 2), Math.round((height - h) / 2 - 30), w, h);
            }
            // Píxeles reales por píxel lógico (con otra escala de monitor, o una imagen reducida)
            readonly property real k: imageRect.width > 0 ? Math.max(1, shot.implicitWidth / imageRect.width) : 1

            // ── Atajos ──
            function pressEscape() {
                const a = win.notes;
                // Primero se cierra la tarjeta del texto leído
                if (win.store.ocrState !== "") {
                    win.store.closeOcr();
                    return;
                }
                if (a.editingId >= 0) {
                    a.endEdit();
                    return;
                }
                if (a.selectedId >= 0) {
                    a.selectedId = -1;
                    return;
                }
                if (chosen && a.count > 0 && !armed) {
                    armed = true;
                    win.store.say("Esc otra vez para descartar");
                    armTimer.restart();
                    return;
                }
                win.store.cancel();
            }

            readonly property var toolKeys: ({
                    [Qt.Key_V]: "move",
                    [Qt.Key_A]: "arrow",
                    [Qt.Key_R]: "rect",
                    [Qt.Key_E]: "ellipse",
                    [Qt.Key_L]: "line",
                    [Qt.Key_P]: "pen",
                    [Qt.Key_H]: "marker",
                    [Qt.Key_T]: "text",
                    [Qt.Key_N]: "counter",
                    [Qt.Key_B]: "pixel",
                    [Qt.Key_S]: "sticker"
                })

            Keys.onPressed: function (e) {
                const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
                const shift = (e.modifiers & Qt.ShiftModifier) !== 0;
                const a = win.notes;
                e.accepted = true;
                if (e.key === Qt.Key_Escape) {
                    pressEscape();
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    if (editorOn && chosen)
                        capture("both");
                } else if (ctrl && e.key === Qt.Key_Z) {
                    shift ? a.redo() : a.undo();
                } else if (ctrl && e.key === Qt.Key_Y) {
                    a.redo();
                } else if (ctrl && e.key === Qt.Key_C) {
                    if (editorOn && chosen)
                        capture("copy");
                } else if (ctrl && e.key === Qt.Key_S) {
                    if (editorOn && chosen)
                        capture("save");
                } else if (e.key === Qt.Key_Delete || e.key === Qt.Key_Backspace) {
                    a.removeSelected();
                } else if (!ctrl && editorOn && chosen && toolKeys[e.key] !== undefined) {
                    a.setTool(toolKeys[e.key]);
                } else {
                    e.accepted = false;
                }
            }

            Timer {
                id: armTimer
                interval: 2500
                onTriggered: root.armed = false
            }

            // ── Exportar: guardar y/o copiar lo que hay dentro del área ──
            // `action`: "both" | "copy" | "save"
            function capture(action) {
                const s = Qt.rect(Math.round(frame.sel.x), Math.round(frame.sel.y), Math.round(frame.sel.width), Math.round(frame.sel.height));
                if (s.width < conf.minSize || s.height < conf.minSize)
                    return;
                if (win.notes.count === 0) {
                    // Sin anotaciones basta recortar la imagen congelada
                    if (win.editMode)
                        win.store.deliver(win.store.editSource, null, action);
                    else
                        win.store.deliver(framePath, [(s.x - imageRect.x) * k, (s.y - imageRect.y) * k, s.width * k, s.height * k], action);
                    return;
                }
                canvasBox.grabToImage(function (res) {
                    const path = win.store.tmpDir + "/export.png";
                    if (res.saveToFile(path))
                        win.store.deliver(path, null, action);
                    else
                        win.store.fail("No se pudo guardar la captura", "");
                }, Qt.size(s.width * k, s.height * k));
            }

            // Lee el texto (o el QR) del área, sin las anotaciones: el recorte de la imagen congelada
            function readText() {
                const s = Qt.rect(Math.round(frame.sel.x), Math.round(frame.sel.y), Math.round(frame.sel.width), Math.round(frame.sel.height));
                if (s.width < conf.minSize || s.height < conf.minSize)
                    return;
                win.store.selScreen = name;
                if (win.editMode)
                    win.store.ocr(win.store.editSource, null);
                else
                    win.store.ocr(framePath, [(s.x - imageRect.x) * k, (s.y - imageRect.y) * k, s.width * k, s.height * k]);
            }

            // ── Elegir el área ──
            function clearSelection() {
                chosen = false;
                hoverWin = null;
                // Al volver a editar, el área es la imagen entera y no se borra
                if (!win.editMode)
                    frame.sel = Qt.rect(0, 0, 0, 0);
            }

            function choose() {
                if (!frame.has)
                    return;
                win.store.selScreen = name;
                if (editorOn)
                    chosen = true;
                else
                    capture("both");
            }

            // Con un solo monitor, "Pantalla" no necesita clic
            function autoScreen() {
                if (!win.isBar || win.editMode || mode !== "screen" || Quickshell.screens.length !== 1)
                    return;
                frame.sel = Qt.rect(0, 0, width, height);
                choose();
            }

            function updateHover(x, y) {
                if (mode === "screen") {
                    frame.sel = Qt.rect(0, 0, width, height);
                    return;
                }
                hoverWin = null;
                frame.sel = Qt.rect(0, 0, 0, 0);
                for (const w of win.store.windows) {
                    if (w.monitor !== name || x < w.x || x >= w.x + w.w || y < w.y || y >= w.y + w.h)
                        continue;
                    const x0 = Math.max(0, w.x), y0 = Math.max(0, w.y);
                    const x1 = Math.min(width, w.x + w.w), y1 = Math.min(height, w.y + w.h);
                    hoverWin = w;
                    frame.sel = Qt.rect(x0, y0, x1 - x0, y1 - y0);
                    return;
                }
            }

            // Un sticker en el centro del área, listo para moverlo, girarlo o cambiarle el tamaño
            function placeSticker(emoji, src) {
                const a = win.notes;
                const size = Math.max(32, Math.min(conf.stickerSize, Math.min(frame.sel.width, frame.sel.height) * 0.6));
                const id = a.add("sticker", {
                    ax: frame.sel.x + (frame.sel.width - size) / 2,
                    ay: frame.sel.y + (frame.sel.height - size) / 2,
                    aw: size,
                    ah: size,
                    emo: emoji,
                    src: src
                });
                a.commit();
                a.setTool("move");
                a.selectedId = id;
                forceActiveFocus();
            }

            // ── Eventos de la tienda ──
            Connections {
                target: win.store
                function onPhaseChanged() {
                    if (win.store.phase !== "open")
                        return;
                    root.armed = false;
                    root.clearSelection();
                    if (win.editMode) {
                        root.chosen = win.isBar;
                        win.store.selScreen = win.store.barScreen;
                    }
                    root.forceActiveFocus();
                    root.autoScreen();
                }
                function onModeChanged() {
                    win.store.closeOcr();
                    root.clearSelection();
                    root.autoScreen();
                }
                function onEditorOnChanged() {
                    if (!root.editorOn && !win.editMode)
                        root.clearSelection();
                    root.autoScreen();
                }
                function onSelScreenChanged() {
                    if (win.store.selScreen !== root.name && !win.editMode)
                        root.clearSelection();
                }
                function onActionRequested(action) {
                    if (!root.chosen || !win.visible)
                        return;
                    if (action === "text")
                        root.readText();
                    else
                        root.capture(action);
                }
                function onStickerPicked(path) {
                    if (root.chosen)
                        root.placeSticker("", "file://" + path);
                }
            }
            Connections {
                target: win.notes
                function onEditingIdChanged() {
                    if (win.notes.editingId < 0)
                        root.forceActiveFocus();
                }
            }

            // ── Fondo (al editar una imagen) y la imagen congelada ──
            Rectangle {
                anchors.fill: parent
                visible: win.editMode
                color: "#e6000000"
            }
            Image {
                id: shot
                x: root.imageRect.x
                y: root.imageRect.y
                width: root.imageRect.width
                height: root.imageRect.height
                source: root.framePath !== "" ? "file://" + root.framePath : ""
                asynchronous: false
                cache: false
                smooth: true
                mipmap: true
            }

            // ── Lienzo: la imagen y las anotaciones, recortadas al área (es lo que se exporta) ──
            Item {
                id: canvasBox
                visible: root.chosen && frame.has
                x: Math.round(frame.sel.x)
                y: Math.round(frame.sel.y)
                width: Math.round(frame.sel.width)
                height: Math.round(frame.sel.height)
                clip: true

                Item {
                    x: -canvasBox.x
                    y: -canvasBox.y
                    width: root.width
                    height: root.height

                    Image {
                        x: root.imageRect.x
                        y: root.imageRect.y
                        width: root.imageRect.width
                        height: root.imageRect.height
                        source: shot.source
                        cache: false
                        smooth: true
                        mipmap: true
                    }
                    Repeater {
                        model: win.notes.list
                        delegate: Annotation {
                            frozen: shot
                            frozenRect: root.imageRect
                        }
                    }
                }
            }

            // ── Marco: oscurece lo de fuera, borde, esquinas y medida ──
            R.RegionFrame {
                id: frame
                anchors.fill: parent
                interactive: !win.editMode && (root.mode === "area" || root.mode === "text") && (!root.chosen || !root.editorOn || win.notes.tool === "move")
                showHandles: !win.editMode && (root.mode === "area" || root.mode === "text")
                showSize: !win.editMode
                hint: win.editMode ? "" : (root.mode === "area" ? "Arrastra para elegir el área" : (root.mode === "text" ? "Arrastra sobre el texto" : (root.mode === "window" ? "Elige una ventana" : "Elige la pantalla")))

                onStarted: {
                    root.chosen = false;
                    win.store.closeOcr();
                    win.store.selScreen = root.name;
                }
                onReleased: {
                    if (root.mode === "text") {
                        root.readText();
                        return;
                    }
                    if (root.mode !== "area")
                        return;
                    win.store.selScreen = root.name;
                    if (root.editorOn)
                        root.chosen = true;
                    else
                        root.capture("both");
                }
            }
            // Al volver a editar, el área es la imagen entera
            Binding {
                target: frame
                property: "sel"
                value: root.imageRect
                when: win.editMode
            }

            // ── Elegir una ventana o la pantalla con el mouse ──
            MouseArea {
                anchors.fill: parent
                enabled: !win.editMode && (root.mode === "window" || root.mode === "screen") && !root.chosen
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: function (e) {
                    root.updateHover(e.x, e.y);
                }
                onEntered: root.updateHover(mouseX, mouseY)
                // Al elegir, esta capa se desactiva y eso también dispara `exited`: lo elegido se conserva
                onExited: if (!root.chosen)
                    root.clearSelection()
                onClicked: root.choose()
            }

            // ── Anotar ──
            AnnotationLayer {
                anchors.fill: parent
                area: frame.sel
                active: root.editorOn && root.chosen
            }

            // ── Herramientas del editor ──
            EditorToolbar {
                id: toolbar
                visible: root.editorOn && root.chosen && frame.has
                readonly property real limit: win.isBar ? root.height - win.conf.barBottom - win.conf.barHeight - 12 : root.height - 12
                readonly property real below: frame.sel.y + frame.sel.height + 10
                width: Math.min(implicitWidth, root.width - 24)
                x: Math.max(12, Math.min(root.width - width - 12, frame.sel.x + frame.sel.width / 2 - width / 2))
                // Debajo del área; si no cabe, encima; si tampoco, dentro (sin tapar la barra de modos)
                y: below + height <= limit ? below : (frame.sel.y - height - 10 >= 12 ? frame.sel.y - height - 10 : Math.max(12, Math.min(frame.sel.y + frame.sel.height - height - 12, limit - height)))
            }
            StickerPanel {
                visible: toolbar.visible && win.notes.tool === "sticker"
                x: Math.max(12, Math.min(root.width - width - 12, toolbar.x + toolbar.width / 2 - width / 2))
                y: toolbar.y - height - 8 >= 12 ? toolbar.y - height - 8 : toolbar.y + toolbar.height + 8
                onPicked: function (emoji, src) {
                    root.placeSticker(emoji, src);
                }
            }

            // ── Texto leído ──
            OcrCard {
                id: ocrCard
                visible: win.store.ocrState !== "" && win.store.selScreen === root.name
                width: Math.max(conf.ocrCardMin, Math.min(conf.ocrCardMax, frame.sel.width))
                maxTextHeight: Math.max(120, root.height / 2 - 130)
                readonly property real limit: win.isBar ? root.height - conf.barBottom - conf.barHeight - 12 : root.height - 12
                // Con la barra del editor debajo del área, la tarjeta va debajo de la barra
                readonly property real below: (toolbar.visible && toolbar.y > frame.sel.y ? toolbar.y + toolbar.height : frame.sel.y + frame.sel.height) + 10
                x: Math.max(12, Math.min(root.width - width - 12, frame.sel.x))
                // Debajo del área; si no cabe, encima; si tampoco, dentro (sin tapar la barra de modos)
                y: below + height <= limit ? below : (frame.sel.y - height - 10 >= 12 ? frame.sel.y - height - 10 : Math.max(12, Math.min(frame.sel.y + frame.sel.height - height - 12, limit - height)))
                onCloseRequested: {
                    win.store.closeOcr();
                    root.forceActiveFocus();
                }
            }

            // ── Barra de modos ──
            Text {
                visible: win.isBar && win.store.hintText !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: modeBar.top
                anchors.bottomMargin: 12
                text: win.store.hintText
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.lg
                font.weight: Font.DemiBold
                style: Text.Outline
                styleColor: "#cc000000"
            }
            ModeBar {
                id: modeBar
                visible: win.isBar
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: win.conf.barBottom
                chosen: root.chosen
            }
        }
    }
}
