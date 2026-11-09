pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../osd/" as O
import "../../" as App

// Brillo de la pantalla con brightnessctl (siempre -c backlight: también existe la luz del
// teclado). No necesita sudo: el usuario está en el grupo video.
Singleton {
    id: store

    property real value: 1          // 0..1
    property int max: 0
    readonly property bool available: max > 0

    function percent() {
        return Math.round(value * 100);
    }

    // Vuelve a leer el brillo real (por si otro programa lo cambió)
    function refresh() {
        infoProc.running = true;
    }

    function set(v) {
        value = Math.max(App.Config.brightness.min, Math.min(1, v));
        writeTimer.restart();
    }

    function step(delta) {
        set(value + delta);
    }

    Process {
        id: infoProc
        command: ["brightnessctl", "-c", "backlight", "-m", "info"]
        stdout: StdioCollector {
            // amdgpu_bl0,backlight,63559,97%,65535
            onStreamFinished: {
                const f = text.trim().split(",");
                if (f.length < 5)
                    return;
                store.max = parseInt(f[4]);
                // No pisar un cambio que aún no se escribió
                if (!writeTimer.running && store.max > 0)
                    store.value = parseInt(f[2]) / store.max;
            }
        }
    }

    Timer {
        id: writeTimer
        interval: App.Config.brightness.writeDelay
        onTriggered: {
            if (store.max > 0)
                Quickshell.execDetached(["brightnessctl", "-c", "backlight", "-q", "set", String(Math.round(store.value * store.max))]);
        }
    }

    Component.onCompleted: refresh()

    // qs ipc call stixshell@brightness up|down (hypr/keybinds/media.lua)
    IpcHandler {
        target: "stixshell@brightness"
        function up(): void {
            store.step(App.Config.brightness.keyStep);
            O.OsdStore.show("brightness");
        }
        function down(): void {
            store.step(-App.Config.brightness.keyStep);
            O.OsdStore.show("brightness");
        }
    }
}
