import QtQuick
import "../../controls/" as C
import "../../../services/launcher/" as L
import "../../../services/launcher/Search.js" as Search
import "../../../services/session/" as SS
import "../../../" as App

// Launcher (Super+R). Buscar apps; con prefijo: e: emojis, c: calculadora, t: terminal.
// Las apps tienen estrella (favoritos arriba). Las acciones de sesión y las acciones de las apps
// aparecen como resultados al buscar.
Item {
    id: root

    // Apps visibles (inyectado)
    property var apps: []

    // La isla debe cerrarse (se lanzó algo)
    signal closeRequested

    readonly property var cfg: App.Config.launcher
    readonly property var store: L.LauncherStore

    // Acción de sesión armada (pide un segundo Enter)
    property string armedKey: ""

    readonly property var context: ({
            apps: apps,
            favorites: store.favorites,
            usage: store.usage,
            emojis: store.emojis,
            session: store.session,
            sessionWords: store.sessionWords,
            sessionGlyphs: store.sessionGlyphs,
            history: store.history,
            canType: store.canType,
            maxResults: cfg.maxResults
        })
    readonly property var found: Search.results(searchInput.text, context)
    readonly property var rows: found.rows
    readonly property var current: list.currentIndex >= 0 && list.currentIndex < rows.length ? rows[list.currentIndex] : null

    function disarm() {
        armedKey = "";
        confirmTimer.stop();
    }

    function activate(row) {
        if (!row)
            return;
        switch (row.kind) {
        case "app":
            closeRequested();
            store.launchApp(row.ref);
            break;
        case "action":
            closeRequested();
            store.launchAction(row.ref);
            break;
        case "session":
            if (row.confirm && armedKey !== row.key) {
                armedKey = row.key;
                confirmTimer.restart();
                return;
            }
            disarm();
            closeRequested();
            SS.SessionStore.run(row.id);
            break;
        case "emoji":
            closeRequested();
            store.insertText(row.text);
            store.use(row.key);
            break;
        case "calc":
            closeRequested();
            store.insertText(row.text);
            break;
        case "terminal":
        case "history":
            closeRequested();
            store.runCommand(row.command);
            break;
        }
    }

    // Ctrl+D: favorito. La selección se queda en la misma app aunque cambie de lugar.
    function toggleFavorite(row) {
        if (!row || row.kind !== "app")
            return;
        const key = row.key;
        store.toggleFavorite(row.favId);
        Qt.callLater(function () {
            const i = root.rows.findIndex(r => r.key === key);
            if (i >= 0)
                list.currentIndex = i;
        });
    }

    onVisibleChanged: {
        if (!visible)
            return;
        searchInput.text = "";
        searchInput.giveFocus();
        disarm();
        list.currentIndex = 0;
        store.checkTyper();
    }

    Timer {
        id: confirmTimer
        interval: App.Config.session.confirmTimeout
        onTriggered: root.armedKey = ""
    }

    Column {
        anchors.fill: parent
        spacing: 10

        C.TextField {
            id: searchInput
            placeholder: "Buscar aplicaciones..."

            onPressedKey: function (key) {
                if (key === Qt.Key_Enter)
                    root.activate(root.current);
                else if (key === Qt.Key_Down)
                    list.incrementCurrentIndex();
                else if (key === Qt.Key_Up)
                    list.decrementCurrentIndex();
            }
            onKeyCombo: function (key, modifiers) {
                if (key === Qt.Key_D)
                    root.toggleFavorite(root.current);
                else if (key === Qt.Key_PageDown)
                    list.currentIndex = Math.min(list.count - 1, list.currentIndex + 8);
                else if (key === Qt.Key_PageUp)
                    list.currentIndex = Math.max(0, list.currentIndex - 8);
            }
            onTextChanged: {
                // Los emojis se leen la primera vez que se usa e:
                if (/^\s*e:/i.test(text))
                    root.store.loadEmojis();
                list.currentIndex = 0;
                root.disarm();
            }
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - searchInput.height - help.height - 2 * parent.spacing
            clip: true
            model: root.rows
            currentIndex: 0

            highlight: Rectangle {
                color: App.Theme.surfaceHigh
                radius: App.Config.radius.md
            }
            highlightMoveDuration: App.Config.anim.highlight
            highlightResizeDuration: 0

            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 1500

            // Moverse con el teclado deja sin armar la acción de sesión
            onCurrentIndexChanged: root.disarm()

            delegate: ResultRow {
                required property var modelData
                required property int index

                width: ListView.view.width
                row: modelData
                selected: ListView.isCurrentItem
                armedText: modelData.kind === "session" && root.armedKey === modelData.key ? modelData.confirmText + " Enter otra vez" : ""

                onClicked: {
                    list.currentIndex = index;
                    root.activate(modelData);
                }
                onStarClicked: root.toggleFavorite(modelData)
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: "Sin aplicaciones"
                color: App.Theme.subtext
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.md
            }
        }

        // ── Pie de ayuda (solo con el buscador vacío) ──
        Text {
            id: help
            width: parent.width
            height: root.cfg.helpHeight
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: searchInput.text === "" ? "e: emojis · c: calculadora · t: terminal · Ctrl+D favorito" : ""
            color: App.Theme.subtext
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.xs
        }
    }
}
