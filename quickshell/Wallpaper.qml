pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string current: ""
    readonly property string statePath: `${Quickshell.env("HOME")}/.cache/quickshell/wallpaper`

    function set(path) {
        if (!path)
            return;
        root.current = path;
        stateWriter.command = ["sh", "-c", `mkdir -p "$(dirname '${root.statePath}')" && printf '%s' '${path}' > '${root.statePath}'`];
        stateWriter.running = true;
    }

    Process {
        id: stateReader
        command: ["cat", root.statePath]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const saved = text.trim();
                if (saved.length > 0)
                    root.current = saved;
            }
        }
    }
    Process {
        id: stateWriter
    }
}
