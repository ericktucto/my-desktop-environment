pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../region/" as RG
import "../../" as App

// Red: Wi-Fi (Quickshell.Networking), conexión por cable y VPN de WireGuard (nmcli, que Quickshell no cubre).
// Las interfaces virtuales de Docker no se muestran (Config.network.ignoredDevices).
Singleton {
    id: store

    readonly property var cfg: App.Config.network
    readonly property string vpnScript: Quickshell.shellPath("scripts/vpn-import.py")
    readonly property string pickScript: Quickshell.shellPath("scripts/pick.py")

    // La vista se abre o se cierra (el diálogo de archivos y el selector de región necesitan la pantalla libre)
    signal openPanel
    signal closePanel

    // qs ipc call stixshell@network open|toggle
    IpcHandler {
        target: "stixshell@network"
        function open(): void {
            store.openPanel();
        }
        function toggle(): void {
            store.toggle();
        }
    }

    // ── Dispositivos ──
    readonly property var devs: Networking.devices.values
    readonly property var wifi: devs.find(d => d.type === DeviceType.Wifi) ?? null
    // Cableada: gestionada, con enlace y que no sea de Docker
    readonly property var wired: devs.filter(d => d.type === DeviceType.Wired && d.nmManaged && !cfg.ignoredDevices.test(d.name) && d.hasLink)
    readonly property bool wiredConnected: wired.some(d => d.connected)

    readonly property bool wifiAvailable: wifi !== null
    readonly property bool enabled: wifiAvailable && Networking.wifiEnabled
    readonly property bool blocked: wifiAvailable && !Networking.wifiHardwareEnabled

    function toggle() {
        if (wifiAvailable && !blocked)
            Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    // ── Redes Wi-Fi ──
    // Sin nombre (ocultas) no salen; si un nombre se repite, la de mejor señal. La conectada primero y luego las guardadas.
    readonly property var networks: {
        if (!wifi)
            return [];
        const best = {};
        for (const n of wifi.networks.values) {
            if (!n.name)
                continue;
            const o = best[n.name];
            if (!o || (n.connected && !o.connected) || (!o.connected && n.signalStrength > o.signalStrength))
                best[n.name] = n;
        }
        return Object.values(best).sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength) || a.name.localeCompare(b.name));
    }
    readonly property var current: networks.find(n => n.connected) ?? null

    readonly property bool online: current !== null || wiredConnected

    function isOpen(n) {
        return n.security === WifiSecurityType.Open || n.security === WifiSecurityType.Owe;
    }

    // Empresa (802.1X): se muestra pero no se configura aquí
    function isEnterprise(n) {
        return n.security === WifiSecurityType.Wpa2Eap || n.security === WifiSecurityType.WpaEap || n.security === WifiSecurityType.Wpa3SuiteB192 || n.security === WifiSecurityType.Leap;
    }

    function glyphFor(n) {
        const g = cfg.signalGlyphs;
        return String.fromCodePoint(g[Math.max(0, Math.min(g.length - 1, Math.floor(n.signalStrength * g.length)))]);
    }

    function networkStatus(n) {
        if (n.state === ConnectionState.Connecting)
            return "Conectando…";
        if (n.connected)
            return "Conectada · clic para desconectar";
        if (isEnterprise(n))
            return "Requiere configuración avanzada";
        if (n.known)
            return "Guardada";
        return isOpen(n) ? "Abierta" : "Segura";
    }

    // Glifo para la barra: señal, cable o sin conexión
    readonly property string barGlyph: {
        if (current)
            return glyphFor(current);
        return String.fromCodePoint(wiredConnected ? cfg.glyphWired : cfg.glyphOff);
    }

    readonly property string statusText: {
        let t;
        if (!wifiAvailable && wired.length === 0)
            t = "Sin Wi-Fi";
        else if (blocked)
            t = "Bloqueado";
        else if (current)
            t = current.name;
        else if (wiredConnected)
            t = "Cableada";
        else
            t = enabled ? "Desconectado" : "Apagado";
        return vpnActive ? t + " · VPN" : t;
    }

    // ── Mensajes cortos ──
    property string message: ""

    function say(text) {
        message = text;
        messageTimer.restart();
    }

    Timer {
        id: messageTimer
        interval: store.cfg.messageTime
        onTriggered: store.message = ""
    }

    // ── Buscar (solo con la vista abierta) ──
    function scan() {
        if (!wifi || !enabled)
            return;
        wifi.scannerEnabled = true;
        run(["nmcli", "device", "wifi", "rescan"], function () {});
    }

    function leave() {
        if (wifi)
            wifi.scannerEnabled = false;
    }

    // ── Conectar ──
    // SSID cuya contraseña se está pidiendo (la fila se despliega) y redes conectadas con contraseña nueva
    property string passwordFor: ""
    property var pskAttempts: ({})

    function activate(n) {
        if (n.state === ConnectionState.Connecting)
            return;
        if (n.connected) {
            n.disconnect();
        } else if (isEnterprise(n)) {
            say("Requiere configuración avanzada");
        } else if (n.known || isOpen(n)) {
            passwordFor = "";
            n.connect();
        } else {
            passwordFor = n.name;
        }
    }

    function connectWith(n, key) {
        passwordFor = "";
        pskAttempts[n.name] = true;
        n.connectWithPsk(key);
    }

    function forget(n) {
        n.forget();
    }

    // Conectar a una red oculta (por nmcli: Quickshell no la ve)
    function connectHidden(ssid, key) {
        const cmd = ["nmcli", "device", "wifi", "connect", ssid, "hidden", "yes"];
        if (key !== "")
            cmd.push("password", key);
        run(cmd, function (out, code, err) {
            say(code === 0 ? "Conectada a «" + ssid + "»" : "No se pudo conectar a «" + ssid + "»");
        });
    }

    Instantiator {
        model: wifi ? wifi.networks.values : []
        delegate: QtObject {
            id: track
            required property var modelData

            property Connections conn: Connections {
                target: track.modelData

                function onConnectionFailed(reason) {
                    const n = track.modelData;
                    const wrongKey = reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout;
                    if (wrongKey && store.pskAttempts[n.name]) {
                        // La conexión quedó guardada con la clave mala: se borra y se vuelve a pedir
                        delete store.pskAttempts[n.name];
                        n.forget();
                        store.say("Contraseña incorrecta");
                        store.passwordFor = n.name;
                    } else {
                        store.say("No se pudo conectar a «" + n.name + "»");
                    }
                }
                function onConnectedChanged() {
                    delete store.pskAttempts[track.modelData.name];
                }
            }
        }
    }

    // ── Portal cautivo ──
    property string portalNotified: ""

    Connections {
        target: Networking
        function onConnectivityChanged() {
            if (Networking.connectivity !== NetworkConnectivity.Portal || !store.current || store.portalNotified === store.current.name)
                return;
            store.portalNotified = store.current.name;
            store.run(["notify-send", "-a", "Red", "-i", "network-wireless", "-A", "open=Abrir", "La red «" + store.current.name + "» pide iniciar sesión", "Abre el navegador para continuar."], function (out) {
                if (out.trim() === "open")
                    Quickshell.execDetached(["xdg-open", store.cfg.portalUrl]);
            });
        }
    }

    // ── VPN (WireGuard y otras de NetworkManager) ──
    // { name, uuid, type, state } con state = "activated" | "activating" | ""
    property var vpns: []
    readonly property bool vpnActive: vpns.some(v => v.state === "activated")

    // nmcli -t separa con ":" y escapa los ":" y "\" del contenido con "\"
    function splitTerse(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length)
                cur += line[++i];
            else if (c === ":") {
                out.push(cur);
                cur = "";
            } else
                cur += c;
        }
        out.push(cur);
        return out;
    }

    function refreshVpns() {
        run(["nmcli", "-t", "-f", "NAME,UUID,TYPE,STATE", "connection", "show"], function (out) {
            const list = [];
            for (const line of out.split("\n")) {
                const f = splitTerse(line);
                if (f.length >= 4 && (f[2] === "wireguard" || f[2] === "vpn"))
                    list.push({
                        name: f[0],
                        uuid: f[1],
                        type: f[2],
                        state: f[3]
                    });
            }
            list.sort((a, b) => a.name.localeCompare(b.name));
            store.vpns = list;
        });
    }

    // Cada cambio en NetworkManager llega por `nmcli monitor`; se relee con un pequeño retraso
    Process {
        id: monitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: line => monitorTimer.restart()
        }
        onExited: monitorRestart.restart()
    }
    Timer {
        id: monitorTimer
        interval: store.cfg.refreshDebounce
        onTriggered: store.refreshVpns()
    }
    Timer {
        id: monitorRestart
        interval: 3000
        onTriggered: monitor.running = true
    }

    function toggleVpn(v) {
        run(["nmcli", "connection", v.state !== "" ? "down" : "up", "uuid", v.uuid], function (out, code) {
            if (code !== 0)
                store.say(v.state !== "" ? "No se pudo desconectar la VPN" : "No se pudo conectar la VPN");
            store.refreshVpns();
        });
    }

    function removeVpn(v) {
        run(["nmcli", "connection", "delete", "uuid", v.uuid], function (out, code) {
            if (code !== 0)
                store.say("No se pudo borrar la VPN");
            store.refreshVpns();
        });
    }

    // ── Agregar una VPN: archivo, imagen con QR, portapapeles o región de la pantalla ──
    // pending: { text, name, endpoint, address } cuando ya se leyó la configuración y falta confirmar
    property var pending: null
    property bool reading: false

    function importFrom(origin) {
        if (reading)
            return;
        pending = null;
        if (origin === "clipboard") {
            reading = true;
            readClipboard();
        } else if (origin === "region") {
            if (RG.RegionStore.pick("vpn", null)) {
                reading = true;
                closePanel();
            }
        } else {
            // El diálogo de GTK necesita la pantalla libre: la isla se cierra y vuelve al terminar
            reading = true;
            closePanel();
            const qr = origin === "qr-file";
            run(["python3", pickScript, "file", Quickshell.env("HOME"), qr ? "Imagen con el QR de WireGuard" : "Configuración de WireGuard"].concat(qr ? ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"] : ["*.conf", "*.txt"]), function (out, code) {
                const path = out.trim();
                if (code !== 0 || path === "") {
                    store.endReading("");
                    return;
                }
                const hint = path.substring(path.lastIndexOf("/") + 1).replace(/\.[^.]*$/, "");
                if (qr)
                    store.decodeQr(path, "");
                else
                    store.run(["cat", path], function (text, c) {
                        store.checkConfig(c === 0 ? text : "", hint);
                    });
            });
        }
    }

    function readClipboard() {
        // Imagen (un QR) o, si no, el texto de la configuración
        const script = 'd="$XDG_RUNTIME_DIR/stixshell/vpn"; mkdir -p "$d"; chmod 700 "$d"; ' + 't=$(wl-paste -l 2>/dev/null | grep -m1 "^image/"); ' + 'if [ -n "$t" ]; then wl-paste -t "$t" > "$d/clip-qr" 2>/dev/null && python3 "$1" qr "$d/clip-qr"; c=$?; rm -f "$d/clip-qr"; exit $c; ' + 'else wl-paste -n 2>/dev/null; fi';
        run(["sh", "-c", script, "_", vpnScript], function (out, code) {
            if (code === 2)
                store.endReading("No se encontró un QR de WireGuard");
            else if (code !== 0 || out.trim() === "")
                store.endReading("El portapapeles no tiene una configuración ni un QR");
            else
                store.checkConfig(out, "");
        });
    }

    function decodeQr(path, cleanup) {
        run(["python3", vpnScript, "qr", path], function (out, code) {
            if (cleanup !== "")
                store.run(["rm", "-f", cleanup], function () {});
            if (code === 3)
                store.endReading("Falta python3-pyzbar");
            else if (code !== 0 || out.trim() === "")
                store.endReading("No se encontró un QR de WireGuard");
            else
                store.checkConfig(out, "");
        });
    }

    // Valida la configuración y propone el nombre (el del archivo si vino de uno)
    function checkConfig(text, hint) {
        const cmd = ["python3", vpnScript, "check"];
        if (hint !== "")
            cmd.push("--hint", hint);
        run(cmd, function (out) {
            let r = null;
            try {
                r = JSON.parse(out);
            } catch (err) {
                // sin respuesta
            }
            if (!r || !r.ok)
                store.endReading(r && r.error ? r.error : "No es una configuración de WireGuard");
            else {
                store.pending = {
                    text: text,
                    name: r.name,
                    endpoint: r.endpoint,
                    address: r.address
                };
                store.endReading("");
            }
        }, text);
    }

    // Termina la lectura: reabre la vista (con la tarjeta si hay configuración) o el mensaje
    function endReading(error) {
        reading = false;
        if (error !== "")
            say(error);
        openPanel();
    }

    function cancelImport() {
        pending = null;
    }

    function confirmImport(name) {
        if (!pending)
            return;
        const text = pending.text;
        pending = null;
        run(["python3", vpnScript, "import", name], function (out) {
            let r = null;
            try {
                r = JSON.parse(out);
            } catch (err) {
                // sin respuesta
            }
            if (r && r.ok)
                store.say("VPN «" + r.name + "» agregada");
            else if (r && /not authorized|insufficient privileges|permission/i.test(r.error))
                store.say("Falta el permiso de NetworkManager (system/networkmanager.sh)");
            else
                store.say(r && r.error ? r.error.substring(0, 80) : "No se pudo agregar la VPN");
            store.refreshVpns();
        }, text);
    }

    Connections {
        target: RG.RegionStore
        function onAccepted(owner, screen, x, y, w, h) {
            if (owner !== "vpn")
                return;
            // La captura espera a que el selector desaparezca de la pantalla
            const d = Quickshell.env("XDG_RUNTIME_DIR") + "/stixshell/vpn";
            const file = d + "/region-qr.png";
            store.run(["sh", "-c", 'mkdir -p "$1"; chmod 700 "$1"; sleep 0.4; grim -g "$2" "$3"', "_", d, Math.round(x) + "," + Math.round(y) + " " + Math.round(w) + "x" + Math.round(h), file], function (out, code) {
                if (code !== 0)
                    store.endReading("No se pudo capturar la pantalla (¿está instalado grim?)");
                else
                    store.decodeQr(file, file);
            });
        }
        function onCanceled(owner) {
            if (owner === "vpn")
                store.endReading("");
        }
    }

    // ── Ejecutar un comando (con texto por stdin, si hace falta) → done(salida, código, errores) ──
    function run(cmd, done, input) {
        const p = runner.createObject(store, {
            command: cmd,
            done: done,
            input: input ?? ""
        });
        p.running = true;
    }

    Component {
        id: runner

        Process {
            id: p
            property var done
            property string input: ""
            property string out: ""
            property string err: ""
            property int code: -1
            property bool outDone: false
            property bool errDone: false
            property bool exitDone: false

            stdinEnabled: input !== ""
            stdout: StdioCollector {
                onStreamFinished: {
                    p.out = text;
                    p.outDone = true;
                    p.finish();
                }
            }
            stderr: StdioCollector {
                onStreamFinished: {
                    p.err = text;
                    p.errDone = true;
                    p.finish();
                }
            }
            onStarted: {
                if (input !== "") {
                    write(input);
                    stdinEnabled = false;
                }
            }
            onExited: function (exitCode, exitStatus) {
                p.code = exitCode;
                p.exitDone = true;
                p.finish();
            }
            function finish() {
                if (!outDone || !errDone || !exitDone)
                    return;
                if (done)
                    done(out, code, err);
                destroy();
            }
        }
    }

    Component.onCompleted: refreshVpns()
}
