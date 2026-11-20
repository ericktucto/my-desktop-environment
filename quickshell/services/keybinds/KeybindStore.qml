pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../settings/" as ST

// Atajos de Hyprland: la lista sale de ~/.cache/stixshell/keybinds.json (la escribe hypr/keybinds/repository.lua
// al cargar y al cambiar uno). Los cambios del usuario se guardan en settings.json (keybinds.overrides) y en
// hypr/keybinds/user.lua, que repository.lua lee al iniciar; en vivo se aplican con `hyprctl eval … rebind`.
Singleton {
    id: store

    readonly property string jsonPath: Quickshell.env("HOME") + "/.cache/stixshell/keybinds.json"
    readonly property string userPath: Quickshell.env("HOME") + "/.config/hypr/keybinds/user.lua"
    readonly property var overrides: ST.SettingsStore.keybinds.overrides

    // [{ id, bind (null = quitado), default, description, group }]
    property var binds: []

    // Grupos en el orden en que aparecen: [{ name, binds: […] }]
    readonly property var groups: {
        const out = [];
        binds.forEach(b => {
            let g = out.find(x => x.name === b.group);
            if (!g) {
                g = {
                    name: b.group,
                    binds: []
                };
                out.push(g);
            }
            g.binds.push(b);
        });
        return out;
    }

    function load() {
        try {
            store.binds = JSON.parse(jsonFile.text());
        } catch (err) {
            store.binds = [];
        }
    }

    FileView {
        id: jsonFile
        path: store.jsonPath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: store.load()
        onFileChanged: reload()
        onLoadFailed: store.binds = []
    }

    Component.onCompleted: load()

    // ¿Ya hay un atajo con esa combinación? (el id del que la usa, o "")
    function conflictOf(bind, exceptId) {
        const n = norm(bind);
        const b = binds.find(x => x.id !== exceptId && x.bind && norm(x.bind) === n);
        return b ? b.id : "";
    }

    function norm(bind) {
        return String(bind).toLowerCase().replace(/\s+/g, "").split("+").sort().join("+");
    }

    function byId(id) {
        return binds.find(b => b.id === id) ?? null;
    }

    function isChanged(b) {
        return b.bind !== b.default;
    }

    // ── Grabar una combinación nueva ──
    // Mientras se graba, Hyprland está en un submapa sin atajos (así la combinación llega a la ventana en vez de
    // disparar su acción). Esc cancela; sin pulsar nada se cancela solo.
    property string recording: ""
    property string recordMessage: ""
    // Hyprland no le pasa la tecla Super a la ventana: se añade con este interruptor (activo por defecto, casi
    // todos los atajos la llevan)
    property bool recordSuper: true

    function submap(name) {
        Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.submap("' + name + '")']);
    }

    function startRecording(id) {
        recording = id;
        recordMessage = "";
        submap("stix-record");
        recordTimer.restart();
    }

    function stopRecording() {
        if (recording === "")
            return;
        recording = "";
        recordMessage = "";
        recordTimer.stop();
        submap("reset");
    }

    Timer {
        id: recordTimer
        interval: 12000
        onTriggered: store.stopRecording()
    }

    // Una combinación pulsada: si ya la usa otro atajo avisa y sigue esperando; si no, la aplica
    function recorded(pressed) {
        if (recording === "" || pressed === "")
            return;
        const bind = recordSuper && !pressed.includes("SUPER") ? "SUPER + " + pressed : pressed;
        const other = conflictOf(bind, recording);
        if (other !== "") {
            recordMessage = "Ya lo usa «" + (byId(other)?.description || other) + "». Pulsa otra combinación o Esc.";
            recordTimer.restart();
            return;
        }
        setBind(recording, bind);
        stopRecording();
    }

    // Cambia el atajo `id` a `bind` (texto "SUPER + SHIFT + Q"); `bind` = "" lo quita
    function setBind(id, bind) {
        const def = byId(id)?.default;
        const o = Object.assign({}, overrides);
        if (bind === def)
            delete o[id];
        else
            o[id] = bind === "" ? false : bind;
        ST.SettingsStore.keybinds.overrides = o;
        writeUser(o);
        rebind(id, bind);
    }

    function reset(id) {
        const def = byId(id)?.default;
        if (def !== undefined)
            setBind(id, def);
    }

    function lua(s) {
        return '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
    }

    function rebind(id, bind) {
        Quickshell.execDetached(["hyprctl", "eval", 'require("keybinds.repository").rebind(' + lua(id) + ", " + (bind === "" ? "nil" : lua(bind)) + ")"]);
    }

    function writeUser(o) {
        const lines = ["-- Generado por Preferencias del sistema → Atajos. No lo edites: se vuelve a escribir.", "return {"];
        Object.keys(o).forEach(id => lines.push("    [" + lua(id) + "] = " + (o[id] === false ? "false" : lua(o[id])) + ","));
        lines.push("}");
        userFile.setText(lines.join("\n") + "\n");
    }

    FileView {
        id: userFile
        path: store.userPath
        printErrors: false
    }

    // qs ipc call stixshell@keybinds record "<id>" (para probar la grabación sin el mouse) · reset "<id>"
    IpcHandler {
        target: "stixshell@keybinds"
        function record(id: string): void {
            store.startRecording(id);
        }
        function reset(id: string): void {
            store.reset(id);
        }
    }
}
