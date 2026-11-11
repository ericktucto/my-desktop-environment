pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "./Search.js" as Search
import "../session/" as S
import "../settings/" as ST
import "../../" as App

// Datos y acciones del launcher: favoritos, uso, historial de comandos, emojis, y cómo lanzar o pegar.
Singleton {
    id: store

    // ── Favoritos (en settings.json) ──
    readonly property var favorites: ST.SettingsStore.launcher.favorites || []

    function isFavorite(id) {
        return favorites.indexOf(id) >= 0;
    }

    // Se reasigna el arreglo entero: así JsonAdapter se entera y lo guarda
    function toggleFavorite(id) {
        const list = favorites.slice();
        const i = list.indexOf(id);
        if (i >= 0)
            list.splice(i, 1);
        else
            list.push(id);
        ST.SettingsStore.launcher.favorites = list;
    }

    // ── Uso e historial (en el estado de la shell, launcher.json) ──
    property var usage: ({})        // "app:firefox" / "emoji:🔥" → veces
    property var history: []        // comandos de t:, el más reciente primero

    function use(key) {
        const u = Object.assign({}, usage);
        u[key] = (u[key] || 0) + 1;
        usage = u;
        save();
    }

    function remember(cmd) {
        const h = history.filter(c => c !== cmd);
        h.unshift(cmd);
        history = h.slice(0, App.Config.launcher.historyMax);
        save();
    }

    function save() {
        saveTimer.restart();
    }

    function load() {
        try {
            const d = JSON.parse(stateFile.text());
            usage = d.usage || ({});
            history = d.history || [];
        } catch (err) {
            // sin archivo todavía
        }
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("launcher.json")
        blockLoading: true
        printErrors: false
    }

    Timer {
        id: saveTimer
        interval: 300
        onTriggered: stateFile.setText(JSON.stringify({
            version: 1,
            usage: store.usage,
            history: store.history
        }))
    }

    // ── Acciones de sesión: son resultados más; se buscan también por estas palabras ──
    readonly property var session: S.SessionStore.actions
    readonly property var sessionWords: ({
            lock: "bloquear lock pantalla",
            suspend: "suspender suspend dormir sleep",
            logout: "cerrar sesion logout salir",
            reboot: "reiniciar reboot restart",
            poweroff: "apagar shutdown poweroff"
        })

    // Ícono de cada acción (glifo de la fuente de íconos)
    readonly property var sessionGlyphs: ({
            lock: 0xf033e,
            suspend: 0xf0904,
            logout: 0xf0343,
            reboot: 0xf0709,
            poweroff: 0xf0425
        })

    // ── Emojis: se leen y normalizan la primera vez que se usa e: ──
    property var emojis: []
    property bool emojisLoaded: false

    function loadEmojis() {
        if (emojisLoaded)
            return;
        emojisLoaded = true;
        try {
            const list = JSON.parse(emojiFile.text());
            for (const e of list) {
                e.sn = Search.normalize(e.n);
                e.se = Search.normalize(e.en);
                e.s = Search.normalize(e.n + " " + e.en + " " + e.k.join(" "));
            }
            emojis = list;
        } catch (err) {
            console.warn("LauncherStore: no se pudieron leer los emojis:", err);
        }
    }

    FileView {
        id: emojiFile
        path: Quickshell.shellPath("assets/emoji/es.json")
        blockLoading: true
        printErrors: false
    }

    // ── Lanzar ──
    function launchApp(entry) {
        // DesktopEntry.execute() ignora Terminal=true (nvim…): esas apps van dentro de kitty
        if (entry.runInTerminal)
            Quickshell.execDetached(["kitty", "-e"].concat(entry.command));
        else
            entry.execute();
        use("app:" + entry.id);
    }

    function launchAction(action) {
        action.execute();
    }

    // Comando en una kitty interactiva: sudo, confirmaciones (y/n) y cualquier pregunta se responden en
    // la propia ventana, tus alias funcionan, y al terminar queda tu shell abierta.
    function runCommand(cmd) {
        const c = cmd.trim();
        if (c === "")
            return;
        Quickshell.execDetached(["kitty", "bash", "-ic", c + "; exec bash"]);
        remember(c);
    }

    // ── Escribir en la ventana activa (wtype) o, si no está instalado, copiar ──
    property bool canType: false

    function checkTyper() {
        typerCheck.running = true;
    }

    Process {
        id: typerCheck
        command: ["sh", "-c", "command -v wtype"]
        stdout: StdioCollector {
            onStreamFinished: store.canType = text.trim() !== ""
        }
    }

    function insertText(text) {
        if (canType)
            // La isla se cierra antes: hay que esperar a que la ventana anterior recupere el foco
            Quickshell.execDetached(["sh", "-c", 'sleep "$2"; wtype -- "$1"', "_", text, String(App.Config.launcher.pasteDelay / 1000)]);
        else
            Quickshell.execDetached(["wl-copy", "--", text]);
    }

    Component.onCompleted: {
        load();
        checkTyper();
    }
}
