import QtQuick
import "../controlcenter/" as CC
import "../../../services/clipboard/" as S
import "../../../services/share/" as SH
import "../../../" as App

// Lado derecho del panel: vista previa del elemento seleccionado, sus datos y los botones de acción.
// El QR, "Abrir con" y "Compartir" se muestran sobre la vista previa.
Item {
    id: root

    property var entry: null
    readonly property string entryId: entry ? entry.id : ""
    readonly property bool isImage: entry ? entry.isImage : false
    readonly property var cfg: App.Config.clipboard
    readonly property var store: S.ClipboardStore

    // La isla debe cerrarse (se copió, se abrió una app…)
    signal closeRequested

    // "" | "qr" | "openwith" | "share"
    property string mode: ""
    property bool confirmingRun: false
    property string qrUrl: ""
    property string qrError: ""
    property var chooserItems: []
    property bool chooserReady: true

    function reset() {
        mode = "";
        confirmingRun = false;
        runTimer.stop();
        qrUrl = "";
        qrError = "";
        chooserItems = [];
        textView.contentY = 0;
    }

    // Carga lo que necesita la vista previa del elemento
    function load() {
        if (!entry) {
            store.clearPreview();
            return;
        }
        if (entry.isImage)
            store.requestImage(entry);
        else
            store.loadPreview(entry.id);
    }

    onEntryIdChanged: {
        reset();
        load();
    }
    onVisibleChanged: {
        if (visible) {
            reset();
            load();
        }
    }

    readonly property string infoText: {
        if (!entry)
            return "";
        if (entry.isImage)
            return "Imagen " + entry.format.toUpperCase() + " · " + (entry.width > 0 ? entry.width + "×" + entry.height + " · " + entry.size : entry.name);
        if (store.previewId !== entry.id)
            return "";
        const n = store.previewLines;
        return store.previewChars + " caracteres · " + n + (n === 1 ? " línea" : " líneas") + (store.previewTruncated ? " · vista recortada" : "");
    }

    // ── Acciones ──
    function copy() {
        store.copy(entry);
        closeRequested();
    }

    function runTerminal() {
        if (!confirmingRun) {
            confirmingRun = true;
            runTimer.restart();
            return;
        }
        runTimer.stop();
        confirmingRun = false;
        store.runInTerminal(entryId);
        closeRequested();
    }

    function showQr() {
        mode = "qr";
        qrUrl = "";
        qrError = "";
        if (!store.qrAvailable) {
            qrError = "Falta instalar python3-qrcode\nsudo xbps-install python3-qrcode";
            return;
        }
        const id = entryId;
        store.makeQr(id, function (url, err) {
            if (root.entryId !== id || root.mode !== "qr")
                return;
            root.qrUrl = url;
            root.qrError = err;
        });
    }

    function showOpenWith() {
        const e = entry;
        mode = "openwith";
        chooserItems = [];
        chooserReady = false;
        store.appsFor(e.mime, function (apps) {
            if (root.entryId !== e.id || root.mode !== "openwith")
                return;
            root.chooserItems = apps.map(a => ({
                        name: a.name,
                        icon: a.icon,
                        ref: a
                    }));
            root.chooserReady = true;
        });
    }

    function doShare(target) {
        const e = entry;
        store.exportFile(e, function (file) {
            SH.ShareStore.share(target.id, file);
        });
        closeRequested();
    }

    // Con un solo destino se comparte directo; con varios se elige
    function showShare() {
        const targets = SH.ShareStore.targetsFor(isImage ? "image" : "text");
        if (targets.length === 1) {
            doShare(targets[0]);
            return;
        }
        chooserItems = targets.map(t => ({
                    name: t.name,
                    glyph: t.glyph,
                    ref: t
                }));
        chooserReady = true;
        mode = "share";
    }

    function chosen(item) {
        if (mode === "openwith") {
            store.openWith(item.ref.id, entry);
            closeRequested();
        } else if (mode === "share") {
            doShare(item.ref);
        }
    }

    Timer {
        id: runTimer
        interval: root.cfg.confirmTimeout
        onTriggered: root.confirmingRun = false
    }

    Column {
        anchors.fill: parent
        spacing: 10
        visible: root.entry !== null

        // ── Vista previa ──
        Rectangle {
            id: frame
            width: parent.width
            height: parent.height - info.height - buttons.height - 2 * parent.spacing
            radius: App.Config.radius.md
            color: App.Theme.surface
            clip: true

            // Texto completo (con tope), seleccionable con el mouse
            Flickable {
                id: textView
                anchors.fill: parent
                anchors.margins: 12
                visible: !root.isImage
                clip: true
                contentWidth: width
                contentHeight: edit.implicitHeight
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds

                TextEdit {
                    id: edit
                    width: textView.width
                    readOnly: true
                    selectByMouse: true
                    // el foco se queda en el buscador, para que las flechas sigan moviendo la lista
                    activeFocusOnPress: false
                    wrapMode: TextEdit.WrapAnywhere
                    color: App.Theme.text
                    selectionColor: App.Theme.primary
                    font.family: App.Config.fonts.mono
                    font.pixelSize: App.Config.fontSize.md
                    text: {
                        if (!root.entry)
                            return "";
                        if (root.store.previewId !== root.entryId)
                            return root.entry.preview;
                        return root.store.previewText + (root.store.previewTruncated ? "\n…" : "");
                    }
                }
            }

            Image {
                id: picture
                anchors.fill: parent
                anchors.margins: 10
                visible: root.isImage
                source: root.isImage ? (root.store.imageUrls[root.entryId] || "") : ""
                sourceSize: Qt.size(900, 900)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            Text {
                anchors.centerIn: parent
                visible: root.isImage && picture.status !== Image.Ready
                text: "Cargando…"
                color: App.Theme.subtext
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
            }

            // ── Capa: QR, Abrir con, Compartir ──
            Rectangle {
                id: overlay
                anchors.fill: parent
                visible: root.mode !== ""
                radius: frame.radius
                color: App.Theme.island

                Item {
                    id: overlayHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    height: 28

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.mode === "qr" ? "Código QR" : (root.mode === "openwith" ? "Abrir con" : "Compartir")
                        color: App.Theme.white
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.lg
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: 14
                        color: closeMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface

                        Text {
                            anchors.centerIn: parent
                            text: String.fromCodePoint(0xf0156)
                            color: App.Theme.white
                            font.family: App.Config.fonts.icons
                            font.pixelSize: App.Config.fontSize.lg
                        }
                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.mode = ""
                        }
                    }
                }

                // QR
                Column {
                    visible: root.mode === "qr"
                    anchors.top: overlayHeader.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Image {
                        visible: root.qrUrl !== ""
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(root.cfg.qrSize, overlay.height - overlayHeader.height - 70)
                        height: width
                        source: root.qrUrl
                        smooth: false
                        cache: false
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        visible: root.qrUrl !== ""
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Escanéalo con el teléfono para copiarlo"
                        color: App.Theme.subtext
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.sm
                    }
                    Text {
                        visible: root.qrUrl === ""
                        anchors.horizontalCenter: parent.horizontalCenter
                        topPadding: 60
                        horizontalAlignment: Text.AlignHCenter
                        text: root.qrError !== "" ? root.qrError : "Generando…"
                        color: root.qrError !== "" ? App.Theme.amber : App.Theme.subtext
                        font.family: App.Config.fonts.text
                        font.pixelSize: App.Config.fontSize.md
                    }
                }

                // Abrir con / Compartir
                ChooserMenu {
                    visible: root.mode === "openwith" || root.mode === "share"
                    anchors.top: overlayHeader.bottom
                    anchors.topMargin: 8
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 12
                    items: root.chooserItems
                    ready: root.chooserReady
                    emptyText: root.mode === "share" ? "No hay ningún destino para compartir" : "No hay aplicaciones para abrir este tipo"
                    onChosen: function (item) {
                        root.chosen(item);
                    }
                }
            }
        }

        Text {
            id: info
            width: parent.width
            height: App.Config.fontSize.sm + 6
            text: root.infoText
            color: App.Theme.subtext
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            elide: Text.ElideRight
        }

        // ── Botones, en una fila: dependen del tipo (texto o imagen). Eliminar va solo con el ícono para que quepan. ──
        Row {
            id: buttons
            width: parent.width
            spacing: 8

            CC.QuickToggle {
                glyph: String.fromCodePoint(0xf018f)
                text: "Copiar"
                onClicked: root.copy()
            }
            CC.QuickToggle {
                visible: !root.isImage
                glyph: String.fromCodePoint(0xf0432)
                text: "QR"
                checked: root.mode === "qr"
                onClicked: root.mode === "qr" ? root.mode = "" : root.showQr()
            }
            CC.QuickToggle {
                visible: root.isImage
                glyph: String.fromCodePoint(0xf03cc)
                text: "Abrir con"
                checked: root.mode === "openwith"
                onClicked: root.mode === "openwith" ? root.mode = "" : root.showOpenWith()
            }
            CC.QuickToggle {
                glyph: String.fromCodePoint(0xf0497)
                text: "Compartir"
                checked: root.mode === "share"
                onClicked: root.mode === "share" ? root.mode = "" : root.showShare()
            }
            CC.QuickToggle {
                visible: !root.isImage
                glyph: String.fromCodePoint(0xf018d)
                text: root.confirmingRun ? "¿Ejecutar?" : "Terminal"
                checked: root.confirmingRun
                activeColor: App.Theme.red
                onClicked: root.runTerminal()
            }
            CC.QuickToggle {
                glyph: String.fromCodePoint(0xf01b4)
                onClicked: root.store.remove(root.entryId)
            }
        }
    }
}
