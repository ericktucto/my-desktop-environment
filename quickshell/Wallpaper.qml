pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper actual. Se guarda en ~/.cache/quickshell/wallpaper para recordarlo al reiniciar.
Singleton {
    id: root

    property string current: ""
    readonly property string statePath: `${Quickshell.env("HOME")}/.cache/quickshell/wallpaper`

    function set(path) {
        if (!path)
            return;
        root.current = path;
        file.setText(path);
    }

    FileView {
        id: file
        path: root.statePath
        printErrors: false
        // Lectura asíncrona: current se llena al cargar
        onLoaded: {
            const saved = text().trim();
            if (saved.length > 0)
                root.current = saved;
        }
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", `${Quickshell.env("HOME")}/.cache/quickshell`])
}
