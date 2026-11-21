pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../apps/" as AP

// Compartir archivos con "destinos" intercambiables. No sabe nada del portapapeles:
// recibe rutas, así que sirve para cualquier cosa que se quiera compartir.
//
// Para sumar un destino (KDE Connect, LocalSend, un enlace…) basta con agregar una entrada a `targets`:
//   id      identificador
//   name    texto del menú
//   glyph   código del ícono (Nerd Font)
//   kinds   qué puede enviar: "text", "image", "file"
//   bin     programa que necesita; si no está instalado, el destino no aparece
//   command función (arreglo de rutas) → arreglo con el comando
Singleton {
    id: store

    readonly property var targets: [
        {
            id: "bluetooth",
            name: "Bluetooth",
            glyph: 0xf00af,
            kinds: ["text", "image", "file"],
            bin: "blueman-sendto",
            command: function (files) {
                return ["blueman-sendto"].concat(files);
            }
        }
    ]

    // Destinos cuyo programa está instalado
    property var available: []

    function targetsFor(kind) {
        return available.filter(t => t.kinds.indexOf(kind) >= 0);
    }

    // `files`: una ruta o un arreglo de rutas
    function share(targetId, files) {
        const t = targets.find(x => x.id === targetId);
        if (t)
            Quickshell.execDetached(t.command([].concat(files)));
    }

    // Abre un archivo con la app predeterminada de su tipo (gio abre con la asociada: un visor, mpv…)
    function openFile(path) {
        Quickshell.execDetached(["gio", "open", path]);
    }

    // El gestor de archivos predeterminado, con el archivo seleccionado (org.freedesktop.FileManager1).
    // No se usa xdg-open: en este equipo kitty-open queda como app de carpetas y las abriría en la terminal.
    function showInFolder(path) {
        const dir = path.substring(0, path.lastIndexOf("/"));
        // Con un gestor de archivos elegido en Preferencias → Apps y launcher se abre la carpeta en ese
        if (AP.AppsStore.command("files", []).length > 0) {
            AP.AppsStore.openFolder(dir);
            return;
        }
        Quickshell.execDetached(["sh", "-c", 'gdbus call --session --dest org.freedesktop.FileManager1 --object-path /org/freedesktop/FileManager1 --method org.freedesktop.FileManager1.ShowItems "[\"$1\"]" "" >/dev/null 2>&1 || gio open "$2"', "_", encodeURI("file://" + path), dir]);
    }

    function refresh() {
        checker.running = true;
    }

    Process {
        id: checker
        command: ["sh", "-c", 'for b in "$@"; do command -v "$b" >/dev/null && echo "$b"; done', "_"].concat(store.targets.map(t => t.bin))
        stdout: StdioCollector {
            onStreamFinished: {
                const have = text.split("\n");
                store.available = store.targets.filter(t => have.indexOf(t.bin) >= 0);
            }
        }
    }

    Component.onCompleted: refresh()
}
