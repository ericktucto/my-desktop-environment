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

    // ── Teclas y tapa (se leen mientras está bloqueado) ──
    property bool capsLock: false
    property bool numLock: true
    // Se tecleó en el teclado numérico con Bloq Num apagado
    property bool numpadHint: false
    property bool lidOpen: true

    function refreshKeys() {
        keysProc.running = true;
        lidProc.running = true;
    }

    // Una tecla de Bloq Mayús o Bloq Num: Hyprland ya cambió el estado un instante después
    function keyPressed(key) {
        if (key === Qt.Key_CapsLock || key === Qt.Key_NumLock)
            keyDelay.restart();
    }

    function noteNumpad(isNumpadNonDigit) {
        if (isNumpadNonDigit && !numLock)
            numpadHint = true;
    }

    function clearNumpad() {
        numpadHint = false;
    }

    // true: esta pantalla muestra las notificaciones (la de la laptop con la tapa abierta; si no hay una así,
    // la primera)
    function notifyScreen(name) {
        const laptop = App.Config.lock.laptopOutputs.test(name);
        if (lidOpen && Quickshell.screens.some(s => App.Config.lock.laptopOutputs.test(s.name)))
            return laptop;
        const external = Quickshell.screens.filter(s => !App.Config.lock.laptopOutputs.test(s.name));
        return external.length > 0 ? external[0].name === name : Quickshell.screens.length > 0 && Quickshell.screens[0].name === name;
    }

    Timer {
        id: keyDelay
        interval: 60
        onTriggered: store.refreshKeys()
    }
    Timer {
        interval: App.Config.lock.keyPoll
        running: store.locked
        repeat: true
        onTriggered: store.refreshKeys()
    }
    Process {
        id: keysProc
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kb = JSON.parse(text).keyboards;
                    store.capsLock = kb.some(k => k.capsLock);
                    store.numLock = kb.some(k => k.numLock);
                    if (store.numLock)
                        store.numpadHint = false;
                } catch (err) {
                    // sin respuesta: se queda como estaba
                }
            }
        }
    }
    Process {
        id: lidProc
        command: ["cat", App.Config.lock.lidState]
        stdout: StdioCollector {
            onStreamFinished: store.lidOpen = !/closed/.test(text)
        }
    }

    function lock() {
        if (locked)
            return;
        state = "";
        numpadHint = false;
        locked = true;
        refreshKeys();
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
