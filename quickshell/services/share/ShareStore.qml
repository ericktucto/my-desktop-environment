pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

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
