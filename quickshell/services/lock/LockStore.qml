pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import "../../" as App

// Estado de la pantalla de bloqueo y autenticación con PAM.
Singleton {
    id: store

    property bool locked: false
    // "": libre · "checking": verificando · "error": contraseña incorrecta
    property string state: ""
    // Cuenta de errores (para la sacudida del campo)
    property int failures: 0
    property string userName: Quickshell.env("USER")

    property string pending: ""

    function lock() {
        if (locked)
            return;
        state = "";
        locked = true;
        if (App.Config.lock.testAutoUnlock > 0)
            testTimer.restart();
    }

    function submit(password) {
        if (state === "checking" || password.length === 0)
            return;
        pending = password;
        state = "checking";
        pam.start();
    }

    function clearError() {
        if (state === "error")
            state = "";
    }

    PamContext {
        id: pam

        onPamMessage: {
            if (responseRequired)
                respond(store.pending);
        }
        onCompleted: result => {
            store.pending = "";
            if (result === PamResult.Success) {
                store.locked = false;
                store.state = "";
            } else {
                store.state = "error";
                store.failures += 1;
            }
        }
        onError: {
            store.pending = "";
            store.state = "error";
            store.failures += 1;
        }
    }

    // Solo para pruebas (Config.lock.testAutoUnlock)
    Timer {
        id: testTimer
        interval: App.Config.lock.testAutoUnlock * 1000
        onTriggered: {
            console.log("[lock] testAutoUnlock");
            store.locked = false;
        }
    }

    // Nombre completo del usuario (campo 5 de passwd)
    Process {
        running: true
        command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = text.trim();
                if (n.length > 0)
                    store.userName = n;
            }
        }
    }

    // qs ipc call stixshell@lock lock
    IpcHandler {
        target: "stixshell@lock"
        function lock(): void {
            store.lock();
        }
    }
}
