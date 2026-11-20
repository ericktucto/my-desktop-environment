pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../settings/" as ST

// Cuentas (Preferencias → Cuentas). Google lo maneja CalendarStore (scripts/gcal.py); aquí está GitHub
// (scripts/github.py): login por código de dispositivo o con un token pegado. El token queda en
// ~/.config/stixshell/github-token, que también lee scripts/links.py.
Singleton {
    id: store

    readonly property string script: Quickshell.shellPath("scripts/github.py")
    readonly property var cfg: ST.SettingsStore.accounts

    // GitHub
    property bool ghConnected: false
    property string ghLogin: ""
    property string ghName: ""
    property string ghAvatar: ""
    // "" | offline | invalid | denied | expired | texto
    property string ghError: ""
    property bool ghBusy: false
    // Login por código: lo que hay que escribir en github.com/login/device
    property string deviceCode: ""
    property string deviceUri: ""

    function applyStatus(j) {
        if (!j)
            return;
        ghConnected = j.connected === true;
        ghLogin = j.login ?? "";
        ghName = j.name ?? "";
        ghAvatar = j.avatar ?? "";
        ghError = j.error ?? "";
    }

    // Se vuelve a leer al abrir la página
    function refresh() {
        if (!statusProc.running) {
            statusProc.command = ["python3", script, "status"];
            statusProc.running = true;
        }
    }

    // Un token pegado (se comprueba con GitHub antes de guardarlo)
    function saveToken(token) {
        const t = token.trim();
        if (t === "" || ghBusy)
            return;
        ghBusy = true;
        ghError = "";
        tokenProc.command = ["sh", "-c", 'printf %s "$1" | python3 "$2" save-token', "_", t, script];
        tokenProc.running = true;
    }

    function logout() {
        logoutProc.command = ["python3", script, "logout"];
        logoutProc.running = true;
    }

    // Login por código de dispositivo (necesita el client_id de una OAuth App de GitHub con «Device flow»)
    function deviceLogin() {
        if (ghBusy)
            return;
        if (cfg.githubClientId.trim() === "") {
            ghError = "no-client";
            return;
        }
        ghBusy = true;
        ghError = "";
        startProc.command = ["python3", script, "device-start", cfg.githubClientId.trim()];
        startProc.running = true;
    }

    function cancelDevice() {
        pollProc.running = false;
        ghBusy = false;
        deviceCode = "";
        deviceUri = "";
    }

    Process {
        id: statusProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    store.applyStatus(JSON.parse(text));
                } catch (err) {}
            }
        }
    }

    Process {
        id: tokenProc
        stdout: StdioCollector {
            onStreamFinished: {
                store.ghBusy = false;
                try {
                    store.applyStatus(JSON.parse(text));
                } catch (err) {
                    store.ghError = "invalid";
                }
            }
        }
    }

    Process {
        id: logoutProc
        onExited: store.applyStatus({
            connected: false
        })
    }

    Process {
        id: startProc
        stdout: StdioCollector {
            onStreamFinished: {
                let j = null;
                try {
                    j = JSON.parse(text);
                } catch (err) {}
                if (!j || !j.device_code) {
                    store.ghBusy = false;
                    store.ghError = j && j.error ? j.error : "offline";
                    return;
                }
                store.deviceCode = j.user_code;
                store.deviceUri = j.verification_uri;
                Quickshell.execDetached(["wl-copy", "--", j.user_code]);
                Quickshell.execDetached(["xdg-open", j.verification_uri]);
                pollProc.command = ["python3", store.script, "device-poll", store.cfg.githubClientId.trim(), j.device_code, String(j.interval ?? 5), String(j.expires_in ?? 900)];
                pollProc.running = true;
            }
        }
    }

    Process {
        id: pollProc
        stdout: StdioCollector {
            onStreamFinished: {
                store.ghBusy = false;
                store.deviceCode = "";
                store.deviceUri = "";
                try {
                    store.applyStatus(JSON.parse(text));
                } catch (err) {}
            }
        }
    }
}
