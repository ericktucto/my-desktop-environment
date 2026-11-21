pragma Singleton
import QtQuick
import Quickshell
import "../settings/" as ST
import "Apps.js" as Apps

// Las apps predeterminadas de la shell (Preferencias → Apps y launcher): la terminal, el navegador y el
// gestor de archivos. Cada una es una app instalada (por su categoría de escritorio) o un comando propio;
// sin elegir nada quedan kitty y las apps del sistema (xdg-open / gio).
Singleton {
    id: store

    readonly property var cfg: ST.SettingsStore.apps
    readonly property var categories: ({
            terminal: "TerminalEmulator",
            browser: "WebBrowser",
            files: "FileManager"
        })

    // Las apps instaladas de un tipo: [{ id, name, command }], por nombre
    function installed(kind) {
        const cat = categories[kind];
        return DesktopEntries.applications.values.filter(e => !e.noDisplay && e.categories.indexOf(cat) >= 0).map(e => ({
                    id: e.id,
                    name: e.name,
                    command: e.command
                })).sort((a, b) => a.name.localeCompare(b.name));
    }

    // El comando de un tipo (terminal | browser | files); `fallback` si no se eligió nada
    function command(kind, fallback) {
        return Apps.resolve(cfg[kind + "Cmd"], cfg[kind], installed(kind), fallback);
    }

    readonly property var terminal: command("terminal", ["kitty"])

    // Una terminal ejecutando `argv` (hold = la ventana queda abierta al terminar)
    function runInTerminal(argv, hold) {
        Quickshell.execDetached(Apps.inTerminal(terminal, argv, !!hold));
    }

    // Una terminal sin programa (la shell del usuario)
    function openTerminal() {
        Quickshell.execDetached(terminal);
    }

    function openUrl(url) {
        const b = command("browser", []);
        Quickshell.execDetached(b.length > 0 ? b.concat([url]) : ["xdg-open", url]);
    }

    // Una carpeta en el gestor de archivos elegido; sin elegir, el del sistema (gio, que respeta la app asociada)
    function openFolder(path) {
        const f = command("files", []);
        Quickshell.execDetached(f.length > 0 ? f.concat([path]) : ["gio", "open", path]);
    }

    // Hyprland lee la terminal de este archivo al pulsar Super+T (sin recargar)
    readonly property string terminalFile: Quickshell.env("HOME") + "/.cache/stixshell/terminal"
    onTerminalChanged: writeTerminal()
    function writeTerminal() {
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1"', "_", terminalFile, Apps.join(terminal)]);
    }
    Component.onCompleted: writeTerminal()
}
