pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../region/" as RG
import "../../" as App

// Red: Wi-Fi (Quickshell.Networking), conexión por cable, VPN de WireGuard y OpenVPN, detalles de cada red (IP, DNS),
// QR para compartir el Wi-Fi y redes de empresa 802.1X (nmcli, que Quickshell no cubre; los comandos largos, en scripts/net.py).
// Las interfaces virtuales de Docker no se muestran (Config.network.ignoredDevices).
Singleton {
    id: store

    readonly property var cfg: App.Config.network
    readonly property string vpnScript: Quickshell.shellPath("scripts/vpn-import.py")
    readonly property string pickScript: Quickshell.shellPath("scripts/pick.py")
    readonly property string netScript: Quickshell.shellPath("scripts/net.py")
    readonly property string qrScript: Quickshell.shellPath("scripts/clipboard-qr.py")
    readonly property string netDir: Quickshell.env("XDG_RUNTIME_DIR") + "/stixshell/net"

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
    // Por nombre (las ocultas no salen; si un nombre se repite, la de mejor señal). Se actualiza con cada cambio de señal.
    readonly property var byName: {
        const best = {};
        if (!wifi)
            return best;
        for (const n of wifi.networks.values) {
            if (!n.name)
                continue;
            const o = best[n.name];
            if (!o || (n.connected && !o.connected) || (!o.connected && n.signalStrength > o.signalStrength))
                best[n.name] = n;
        }
        return best;
    }
    readonly property var current: Object.values(byName).find(n => n.connected) ?? null
    readonly property string currentName: current ? current.name : ""

    // El orden que se ve (nombres) queda fijo: la lista no salta mientras se mira o se escribe una contraseña.
    // Se reordena al abrir la vista, en "Buscar de nuevo" y al conectar o desconectar (la conectada va primero,
    // luego las guardadas, la señal y el nombre). Una red nueva va al final y una que desaparece se quita.
    property ListModel order: ListModel {}

    function sortedNames() {
        return Object.keys(byName).sort((a, b) => {
            const x = byName[a], y = byName[b];
            return (y.connected - x.connected) || (y.known - x.known) || (y.signalStrength - x.signalStrength) || a.localeCompare(b);
        });
    }

    function syncOrder(resort) {
        const first = order.count === 0;
        const have = {};
        for (let i = order.count - 1; i >= 0; i--) {
            const nm = order.get(i).name;
            if (byName[nm])
                have[nm] = true;
            else
                order.remove(i);
        }
        for (const nm of Object.keys(byName)) {
            if (!have[nm])
                order.append({
                    name: nm
                });
        }
        if (!resort && !first)
            return;
        const want = sortedNames();
        for (let i = 0; i < want.length; i++) {
            if (order.get(i).name === want[i])
                continue;
            for (let j = i + 1; j < order.count; j++) {
                if (order.get(j).name === want[i]) {
                    order.move(j, i, 1);
                    break;
                }
            }
        }
    }

    onByNameChanged: syncOrder(false)
    onCurrentNameChanged: syncOrder(true)

    readonly property bool online: current !== null || wiredConnected

    function isOpen(n) {
        return n.security === WifiSecurityType.Open || n.security === WifiSecurityType.Owe;
    }

    // Empresa (802.1X): pide usuario y contraseña (formulario)
    function isEnterprise(n) {
        return n.security === WifiSecurityType.Wpa2Eap || n.security === WifiSecurityType.WpaEap || n.security === WifiSecurityType.Wpa3SuiteB192 || n.security === WifiSecurityType.Leap;
    }

    function glyphFor(n, withAlert) {
        const g = withAlert ? cfg.signalGlyphsAlert : cfg.signalGlyphs;
        return String.fromCodePoint(g[Math.max(0, Math.min(g.length - 1, Math.floor(n.signalStrength * g.length)))]);
    }

    function networkStatus(n) {
        if (n.state === ConnectionState.Connecting)
            return "Conectando…";
        if (n.connected)
            return portal ? "Conectada · Iniciar sesión" : (limited ? "Conectada · Sin internet" : "Conectada · clic para desconectar");
        if (n.known)
            return "Guardada";
        if (isEnterprise(n))
            return "Empresa · clic para configurar";
        if (n.known)
            return "Guardada";
        return isOpen(n) ? "Abierta" : "Segura";
    }

    // Glifo para la barra: señal, cable o sin conexión
    readonly property string barGlyph: {
        // Con cable y Wi-Fi a la vez, el cable (es la conexión principal)
        if (wiredConnected)
            return String.fromCodePoint(cfg.glyphWired);
        if (current)
            return glyphFor(current, alert);
        return String.fromCodePoint(cfg.glyphOff);
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
        if (portal)
            t += " · Iniciar sesión";
        else if (limited)
            t += " · Sin internet";
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
        syncOrder(true);
        checkNow();
        wifi.scannerEnabled = true;
        run(["nmcli", "device", "wifi", "rescan"], function () {});
    }

    function leave() {
        if (wifi)
            wifi.scannerEnabled = false;
    }

    // ── Conectar ──
    // SSID cuya contraseña se está pidiendo (pantalla propia en la vista de red), si está conectando con ella ("connecting")
    // y el error ("Contraseña incorrecta"). pskAttempts: redes que se conectan con una contraseña nueva.
    property string passwordFor: ""
    property string pskState: ""
    property string pskError: ""
    property var pskAttempts: ({})

    function closePassword() {
        passwordFor = "";
        pskState = "";
        pskError = "";
        pskTimer.stop();
    }

    function activate(n) {
        if (n.state === ConnectionState.Connecting)
            return;
        if (n.connected) {
            n.disconnect();
        } else if (isEnterprise(n) && !n.known) {
            closePassword();
            enterpriseFor = n.name;
        } else if (n.known || isOpen(n)) {
            closePassword();
            n.connect();
        } else {
            pskState = "";
            pskError = "";
            passwordFor = n.name;
        }
    }

    function connectWith(n, key) {
        pskAttempts[n.name] = true;
        pskError = "";
        pskState = "connecting";
        pskTimer.restart();
        n.connectWithPsk(key);
    }

    // Si no conecta ni falla en este tiempo, se avisa
    Timer {
        id: pskTimer
        interval: store.cfg.pskTimeout
        onTriggered: {
            if (store.pskState === "connecting")
                store.pskFail("No se pudo conectar");
        }
    }

    function pskFail(text) {
        pskTimer.stop();
        pskState = "";
        pskError = text;
    }

    function securityText(n) {
        switch (n.security) {
        case WifiSecurityType.Open:
            return "Abierta";
        case WifiSecurityType.Owe:
            return "Abierta (cifrada)";
        case WifiSecurityType.Sae:
            return "Segura · WPA3";
        case WifiSecurityType.Wpa2Psk:
            return "Segura · WPA2";
        case WifiSecurityType.WpaPsk:
            return "Segura · WPA";
        case WifiSecurityType.StaticWep:
        case WifiSecurityType.DynamicWep:
            return "Segura · WEP";
        default:
            return "Segura";
        }
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
                    const open = store.passwordFor === n.name;
                    if (wrongKey && store.pskAttempts[n.name]) {
                        // La conexión quedó guardada con la clave mala: se borra y se vuelve a pedir
                        delete store.pskAttempts[n.name];
                        n.forget();
                        if (open) {
                            store.pskFail("Contraseña incorrecta");
                        } else {
                            store.say("Contraseña incorrecta");
                        }
                    } else if (open) {
                        store.pskFail("No se pudo conectar");
                    } else {
                        store.say("No se pudo conectar a «" + n.name + "»");
                    }
                }
                function onConnectedChanged() {
                    delete store.pskAttempts[track.modelData.name];
                    if (track.modelData.connected && store.passwordFor === track.modelData.name) {
                        store.closePassword();
                        store.say("Conectada a «" + track.modelData.name + "»");
                    }
                }
            }
        }
    }

    // ── Portal cautivo y "sin internet" ──
    // NetworkManager verifica internet (system/networkmanager.sh) y dice Portal (la red pide iniciar sesión) o
    // Limited (conecta, pero sin salida). Mientras tanto se vuelve a verificar cada Config.network.recheck.
    readonly property int connectivity: cfg.testConnectivity === "portal" ? NetworkConnectivity.Portal : (cfg.testConnectivity === "limited" ? NetworkConnectivity.Limited : Networking.connectivity)
    readonly property bool canCheck: Networking.canCheckConnectivity
    readonly property bool portal: online && connectivity === NetworkConnectivity.Portal
    readonly property bool limitedRaw: online && connectivity === NetworkConnectivity.Limited
    // "limited" dura un instante al conectar: se espera antes de avisar
    property bool limited: false
    readonly property bool alert: portal || limited
    readonly property string netName: current ? current.name : (wiredConnected ? "Cableada" : "")
    property bool portalNotified: false

    onLimitedRawChanged: {
        if (limitedRaw) {
            limitedTimer.restart();
        } else {
            limitedTimer.stop();
            limited = false;
        }
    }

    Timer {
        id: limitedTimer
        interval: store.cfg.limitedDelay
        onTriggered: store.limited = store.limitedRaw
    }

    function checkNow() {
        if (canCheck)
            Networking.checkConnectivity();
    }

    Timer {
        interval: store.cfg.recheck
        repeat: true
        running: store.canCheck && (store.portal || store.limitedRaw)
        onTriggered: store.checkNow()
    }

    onPortalChanged: {
        if (portal) {
            if (portalNotified)
                return;
            portalNotified = true;
            const name = netName;
            run(["notify-send", "-a", "Red", "-i", "network-wireless", "-A", "open=Iniciar sesión", "La red «" + name + "» pide iniciar sesión", "Inicia sesión para tener internet."], function (out) {
                if (out.trim() === "open")
                    store.openPortal();
            });
        } else if (portalNotified) {
            if (!online) {
                portalNotified = false;
            } else if (connectivity === NetworkConnectivity.Full) {
                portalNotified = false;
                Quickshell.execDetached(["notify-send", "-a", "Red", "-i", "network-wireless", "-t", "4000", "Ya tienes internet", "«" + netName + "»"]);
            }
        }
    }

    // Abre la página de inicio de sesión del router (la que él pone en lugar de la dirección de verificación)
    function openPortal() {
        run(["python3", netScript, "portal-url", cfg.checkUrl], function (out) {
            let url = cfg.portalUrl;
            try {
                const j = JSON.parse(out);
                if (j.ok && j.url)
                    url = j.url;
            } catch (e) {}
            Quickshell.execDetached(["xdg-open", url]);
        });
    }

    // ── Detalles de una red (IP, DNS, conexión automática) ──
    // { kind: "wifi"|"wired", key, title, subtitle, uuid, name, method, addresses, gateway, dns, ignoreAutoDns,
    //   autoconnect, security, live: {device, ip, gateway, dns, mac} | null }
    property var details: null
    // /etc/resolv.conf enlaza al de NetworkManager (system/networkmanager.sh): si no, el DNS de la VPN no se aplica
    property bool resolvOk: true

    function openDetails(n) {
        closePassword();
        closeShare();
        run(["python3", netScript, "profile", "--ssid", n.name], function (out) {
            store.gotDetails(out, {
                kind: "wifi",
                key: n.name,
                title: n.name,
                subtitle: n.connected ? "Conectada · Señal " + Math.round(n.signalStrength * 100) + " %" : "Guardada"
            });
        });
        checkResolv();
    }

    function openWiredDetails(dev) {
        closeShare();
        run(["python3", netScript, "profile", "--dev", dev.name], function (out) {
            store.gotDetails(out, {
                kind: "wired",
                key: dev.name,
                title: "Cableada",
                subtitle: dev.connected ? "Conectada · " + dev.name : dev.name
            });
        });
        checkResolv();
    }

    function gotDetails(out, head) {
        let r = null;
        try {
            r = JSON.parse(out);
        } catch (err) {
            // sin respuesta
        }
        if (!r || !r.ok || !r.found) {
            say("Esta red no tiene un perfil guardado");
            return;
        }
        for (const k in head)
            r[k] = head[k];
        details = r;
    }

    // Recarga los datos en vivo (tras guardar)
    function reloadDetails() {
        if (!details)
            return;
        const d = details;
        const args = d.kind === "wifi" ? ["--ssid", d.key] : ["--dev", d.key];
        run(["python3", netScript, "profile"].concat(args), function (out) {
            store.gotDetails(out, {
                kind: d.kind,
                key: d.key,
                title: d.title,
                subtitle: d.subtitle
            });
        });
    }

    function checkResolv() {
        run(["sh", "-c", '[ "$(readlink /etc/resolv.conf)" = /run/NetworkManager/resolv.conf ]'], function (out, code) {
            store.resolvOk = code === 0;
        });
    }

    // form: { method: "auto"|"manual", address, gateway, dns: "auto"|"1.1.1.1,…", autoconnect: bool }
    function saveDetails(form) {
        if (!details)
            return;
        const cmd = ["python3", netScript, "set-ip", details.uuid, "--method", form.method, "--dns", form.dns, "--autoconnect", form.autoconnect ? "yes" : "no"];
        if (form.method === "manual")
            cmd.push("--address", form.address, "--gateway", form.gateway);
        if (details.live)
            cmd.push("--dev", details.live.device);
        run(cmd, function (out) {
            let r = null;
            try {
                r = JSON.parse(out);
            } catch (err) {
                // sin respuesta
            }
            if (r && r.ok) {
                store.say(r.applied === "reconnected" ? "Guardado · la red se reconectó" : "Guardado");
                store.reloadDetails();
            } else {
                store.say(r && r.error ? r.error : "No se pudo guardar");
            }
        });
    }

    function closeDetails() {
        closeShare();
        details = null;
    }

    function forgetDetails() {
        if (!details || details.kind !== "wifi")
            return;
        const n = byName[details.key];
        if (n)
            n.forget();
        closeDetails();
    }

    // ── Compartir el Wi-Fi con un QR ──
    // share: { ssid, psk, png, security } | null
    property var share: null
    property int shareSerial: 0

    function startShare() {
        if (!details || details.kind !== "wifi")
            return;
        run(["python3", netScript, "share", details.uuid], function (out) {
            let r = null;
            try {
                r = JSON.parse(out);
            } catch (err) {
                // sin respuesta
            }
            if (!r || !r.ok) {
                store.say(r && r.error ? r.error : "No se pudo leer la red");
                return;
            }
            const png = store.netDir + "/wifi-qr.png";
            store.run(["sh", "-c", 'mkdir -p "$1"; chmod 700 "$1"; python3 "$2" "$3"', "_", store.netDir, store.qrScript, png], function (o, code) {
                if (code !== 0) {
                    store.say("No se pudo generar el QR");
                    return;
                }
                store.shareSerial++;
                store.share = {
                    ssid: r.ssid,
                    psk: r.psk,
                    security: r.security,
                    png: png
                };
            }, r.payload);
        });
    }

    function closeShare() {
        if (!share)
            return;
        const png = share.png;
        share = null;
        run(["rm", "-f", png], function () {});
    }

    function copyPassword() {
        if (share && share.psk !== "")
            run(["wl-copy"], function () {
                store.say("Contraseña copiada");
            }, share.psk);
    }

    // ── Red de empresa (802.1X) ──
    // enterpriseFor: SSID cuyo formulario está abierto; enterpriseDraft: lo escrito antes de un fallo (sin contraseña)
    property string enterpriseFor: ""
    property var enterpriseDraft: null
    property bool enterpriseBusy: false

    // form: { eap, phase2, identity, anonymous, password, ca: "system"|"none"|<ruta>, domain }
    function connectEnterprise(form) {
        const ssid = enterpriseFor;
        const cmd = ["python3", netScript, "enterprise", ssid, "--eap", form.eap, "--phase2", form.phase2, "--identity", form.identity, "--ca", form.ca];
        if (form.anonymous !== "")
            cmd.push("--anonymous", form.anonymous);
        if (form.domain !== "")
            cmd.push("--domain", form.domain);
        enterpriseBusy = true;
        const draft = {
            eap: form.eap,
            phase2: form.phase2,
            identity: form.identity,
            anonymous: form.anonymous,
            ca: form.ca,
            domain: form.domain
        };
        run(cmd, function (out) {
            store.enterpriseBusy = false;
            let r = null;
            try {
                r = JSON.parse(out);
            } catch (err) {
                // sin respuesta
            }
            if (r && r.ok) {
                store.enterpriseFor = "";
                store.enterpriseDraft = null;
                store.say("Conectada a «" + ssid + "»");
            } else {
                // El formulario sigue abierto con lo escrito (menos la contraseña)
                store.enterpriseDraft = draft;
                store.say(r && r.error ? r.error : "No se pudo conectar a «" + ssid + "»");
            }
        }, form.password);
    }

    function cancelEnterprise() {
        enterpriseFor = "";
        enterpriseDraft = null;
    }

    // Certificado de la red: el diálogo de GTK necesita la pantalla libre (la isla se cierra y vuelve)
    function pickCaCert(done) {
        closePanel();
        run(["python3", pickScript, "file", Quickshell.env("HOME"), "Certificado de la red", "*.pem", "*.crt", "*.cer", "*.der"], function (out, code) {
            store.openPanel();
            if (code === 0 && out.trim() !== "")
                done(out.trim());
        });
    }

    // ── VPN (WireGuard, OpenVPN y otras de NetworkManager) ──
    // { name, uuid, type, kind, state } con kind = "wireguard" | "openvpn" | "vpn" y state = "activated" | "activating" | ""
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
            for (const v of list)
                v.kind = v.type === "wireguard" ? "wireguard" : ((store.vpnKinds[v.uuid] ?? "") || "vpn");
            store.vpns = list;
            // Las "vpn" de NetworkManager son plugins: se pregunta cuál (OpenVPN…) una vez por conexión
            const unknown = list.filter(v => v.type === "vpn" && !(v.uuid in store.vpnKinds)).map(v => v.uuid);
            if (unknown.length > 0)
                store.run(["sh", "-c", 'for u in "$@"; do echo "$u $(nmcli -g vpn.service-type connection show uuid "$u")"; done', "_"].concat(unknown), function (o) {
                    const kinds = Object.assign({}, store.vpnKinds);
                    for (const l of o.split("\n")) {
                        const [u, svc] = l.trim().split(" ");
                        if (u)
                            kinds[u] = svc && svc.endsWith("openvpn") ? "openvpn" : "vpn";
                    }
                    store.vpnKinds = kinds;
                    store.refreshVpns();
                });
        });
    }
    property var vpnKinds: ({})

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
            run(["python3", pickScript, "file", Quickshell.env("HOME"), qr ? "Imagen con el QR de WireGuard" : "Configuración de VPN (WireGuard u OpenVPN)"].concat(qr ? ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"] : ["*.conf", "*.ovpn", "*.txt"]), function (out, code) {
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
                        store.checkConfig(c === 0 ? text : "", hint, path);
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
    function checkConfig(text, hint, path) {
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
                store.endReading(r && r.error ? r.error : "No es una configuración de WireGuard ni de OpenVPN");
            else {
                store.pending = {
                    text: text,
                    name: r.name,
                    type: r.type,
                    endpoint: r.endpoint,
                    address: r.address,
                    fullTunnel: r.fullTunnel,
                    allowed: r.allowed,
                    needsAuth: r.needsAuth,
                    // Un .ovpn se importa desde su archivo (sus certificados suelen estar en la misma carpeta)
                    path: r.type === "openvpn" && path ? path : ""
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

    function confirmImport(name, user, password) {
        if (!pending)
            return;
        const p = pending;
        pending = null;
        const withAuth = p.type === "openvpn" && p.needsAuth && user !== "";
        const cmd = ["python3", vpnScript, "import", name, "--type", p.type, "--dns-priority", String(cfg.vpnDnsPriority)];
        if (p.path !== "")
            cmd.push("--path", p.path);
        if (withAuth)
            cmd.push("--user", user);
        // Con usuario, la contraseña va en la primera línea de stdin (no en la línea de órdenes)
        const text = (withAuth ? password + "\n" : "") + p.text;
        run(cmd, function (out) {
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
