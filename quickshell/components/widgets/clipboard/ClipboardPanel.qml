import QtQuick
import "../../controls/" as C
import "../controlcenter/" as CC
import "../../../services/clipboard/" as S
import "../../../services/share/" as SH
import "../../../" as App

// Modo "clipboard" de la isla central: búsqueda arriba, lista a la izquierda y vista previa
// con las acciones a la derecha.
Item {
    id: root

    readonly property var cfg: App.Config.clipboard
    readonly property var store: S.ClipboardStore

    // La isla debe cerrarse
    signal closeRequested

    property bool confirmingWipe: false

    // Elementos que pasan el filtro de la búsqueda
    readonly property var filtered: {
        const q = search.text.toLowerCase().trim();
        const all = store.entries;
        return q ? all.filter(e => e.search.indexOf(q) >= 0) : all;
    }
    readonly property var current: list.currentIndex >= 0 && list.currentIndex < filtered.length ? filtered[list.currentIndex] : null

    function copyCurrent() {
        if (!current)
            return;
        store.copy(current);
        closeRequested();
    }

    onVisibleChanged: {
        if (!visible)
            return;
        confirmingWipe = false;
        wipeTimer.stop();
        search.text = "";
        list.currentIndex = 0;
        search.giveFocus();
        store.refresh();
        SH.ShareStore.refresh();
    }

    // Si el historial se vacía, se cancela la confirmación
    onFilteredChanged: if (store.entries.length === 0)
        confirmingWipe = false

    Timer {
        id: wipeTimer
        interval: root.cfg.confirmTimeout
        onTriggered: root.confirmingWipe = false
    }

    Column {
        anchors.fill: parent
        spacing: 12

        // ── Buscador y Borrar todo ──
        Row {
            id: top
            width: parent.width
            spacing: 8

            C.TextField {
                id: search
                width: top.width - wipe.width - top.spacing
                placeholder: "Buscar en el portapapeles..."

                onPressedKey: function (key) {
                    if (key === Qt.Key_Enter)
                        root.copyCurrent();
                    else if (key === Qt.Key_Down)
                        list.incrementCurrentIndex();
                    else if (key === Qt.Key_Up)
                        list.decrementCurrentIndex();
                }
                onTextChanged: list.currentIndex = 0
            }

            CC.QuickToggle {
                id: wipe
                enabled: root.store.entries.length > 0
                opacity: enabled ? 1 : 0.4
                glyph: String.fromCodePoint(0xf05e8)
                text: root.confirmingWipe ? "¿Borrar todo?" : "Borrar todo"
                checked: root.confirmingWipe
                activeColor: App.Theme.red
                onClicked: {
                    if (root.confirmingWipe) {
                        wipeTimer.stop();
                        root.confirmingWipe = false;
                        root.store.wipe();
                    } else {
                        root.confirmingWipe = true;
                        wipeTimer.restart();
                    }
                }
            }
        }

        // ── Lista | vista previa ──
        Item {
            width: parent.width
            height: parent.height - top.height - parent.spacing

            ClipList {
                id: list
                width: root.cfg.listWidth
                height: parent.height
                ids: root.filtered.map(e => e.id)
                onCopyRequested: function (entry) {
                    root.store.copy(entry);
                    root.closeRequested();
                }
            }

            ClipPreview {
                x: root.cfg.listWidth + root.cfg.gap
                width: parent.width - x
                height: parent.height
                entry: root.current
                onCloseRequested: root.closeRequested()
            }

            // Vacío, sin resultados o sin vigilante
            Column {
                visible: root.filtered.length === 0
                anchors.centerIn: parent
                width: parent.width * 0.8
                spacing: 6

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: !root.store.loaded ? "" : (root.store.entries.length === 0 ? "El portapapeles está vacío" : "Sin resultados")
                    color: App.Theme.subtext
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.lg
                }
                Text {
                    visible: root.store.loaded && !root.store.watching
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "Nada está guardando lo que copias.\nLanza wl-paste --watch cliphist store (ver hypr/autostart.lua)."
                    color: App.Theme.amber
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.sm
                }
            }
        }
    }
}
