pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import "../settings/" as ST
import "../../" as App

// Bluetooth: adaptador, dispositivos, conectar y emparejar, y el agente de BlueZ (scripts/bt-agent.py) que
// hace las preguntas de emparejamiento (confirmar un código, escribir un PIN). Quickshell no trae agente.
Singleton {
    id: store

    readonly property var cfg: App.Config.bluetooth
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: available && adapter.enabled
    readonly property bool blocked: available && adapter.state === BluetoothAdapterState.Blocked
    readonly property bool busy: available && (adapter.state === BluetoothAdapterState.Enabling || adapter.state === BluetoothAdapterState.Disabling)
    readonly property bool scanning: available && adapter.discovering
    readonly property string hostName: available ? adapter.name : ""

    // Se ve al abrir y al cerrar el panel (la vista, la barra y el agente avisan por aquí)
    signal openPanel

    // qs ipc call stixshell@bluetooth open|toggle
    IpcHandler {
        target: "stixshell@bluetooth"
        function open(): void {
            store.openPanel();
        }
        function toggle(): void {
            store.toggle();
        }
    }

    // ── Dispositivos ──
    readonly property var allDevices: available ? adapter.devices.values : []

    function byName(a, b) {
        return a.name.localeCompare(b.name);
    }

    // Emparejados: los conectados primero y luego por nombre
    readonly property var paired: allDevices.filter(d => d.paired || d.bonded).sort((a, b) => (b.connected - a.connected) || byName(a, b))
    // Disponibles: los que BlueZ ve y no están emparejados. Se ocultan los que solo tienen dirección.
    readonly property var discovered: allDevices.filter(d => !(d.paired || d.bonded) && d.name !== "" && !/^([0-9A-Fa-f]{2}[-:]){5}[0-9A-Fa-f]{2}$/.test(d.name)).sort(byName)
    readonly property var connected: allDevices.filter(d => d.connected)

    // Batería del único dispositivo conectado que la informa (para la pill de la barra)
    readonly property var batteryDevice: connected.length === 1 && connected[0].batteryAvailable ? connected[0] : null

    function glyphFor(d) {
        return String.fromCodePoint(cfg.glyphs[d.icon] ?? cfg.glyphDefault);
    }

    function percent(d) {
        return Math.round(d.battery * 100);
    }

    readonly property string statusText: {
        if (!available)
            return "Sin adaptador";
        if (blocked)
            return "Bloqueado";
        if (!enabled)
            return "Apagado";
        if (connected.length === 0)
            return "Encendido";
        return connected.length === 1 ? connected[0].name : connected.length + " conectados";
    }

    function deviceStatus(d) {
        if (d.pairing)
            return "Emparejando…";
        if (d.state === BluetoothDeviceState.Connecting)
            return "Conectando…";
        if (d.state === BluetoothDeviceState.Disconnecting)
            return "Desconectando…";
        if (d.connected)
            return "Conectado" + (d.batteryAvailable ? " · " + percent(d) + " %" : "");
        if (d.paired || d.bonded)
            return "Emparejado · clic para conectar";
        return "Clic para emparejar";
    }

    // ── Mensajes cortos ("No se pudo conectar") ──
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

    // ── Encender y apagar ──
    function setEnabled(on) {
        if (!available || busy)
            return;
        if (!on) {
            leave();
            adapter.enabled = false;
        } else if (blocked) {
            // rfkill bloquea el adaptador: se desbloquea y, al terminar, se enciende
            unblock.running = true;
        } else {
            adapter.enabled = true;
        }
    }

    function toggle() {
        setEnabled(!enabled);
    }

    Process {
        id: unblock
        command: ["rfkill", "unblock", "bluetooth"]
        onExited: function (code) {
            if (code !== 0)
                store.say("Bloqueado por el sistema");
            else if (store.available)
                store.adapter.enabled = true;
        }
    }

    // ── Recordar si lo dejaste apagado ──
    // BlueZ lo enciende en cada arranque. Tras armDelay se aplica lo guardado y desde entonces se guarda
    // cada cambio (también los hechos con bluetoothctl).
    property bool armed: false

    onAvailableChanged: {
        armed = false;
        armTimer.restart();
    }
    onEnabledChanged: {
        if (armed && available)
            ST.SettingsStore.bluetooth.enabled = enabled;
    }

    Timer {
        id: armTimer
        interval: store.cfg.armDelay
        running: true
        onTriggered: {
            if (store.available && !ST.SettingsStore.bluetooth.enabled && store.adapter.enabled)
                store.adapter.enabled = false;
            store.armed = true;
        }
    }

    // ── Buscar y ser visible (solo con la vista abierta) ──
    function scan() {
        if (!enabled)
            return;
        adapter.discovering = true;
        // BlueZ deja de mostrarla a los 180 s: el botón de buscar también la vuelve a mostrar
        adapter.discoverable = true;
        scanTimer.restart();
    }

    // Al cerrar la vista: deja de buscar y de ser visible
    function leave() {
        scanTimer.stop();
        if (available) {
            adapter.discovering = false;
            adapter.discoverable = false;
        }
    }

    // A los 60 s deja de buscar (gasta batería), pero sigue visible mientras la vista esté abierta
    Timer {
        id: scanTimer
        interval: store.cfg.scanTimeout
        onTriggered: {
            if (store.available)
                store.adapter.discovering = false;
        }
    }

    // ── Acciones sobre un dispositivo ──
    // Intentos en curso: dirección → "connect" | "pair" (para avisar si fallan)
    property var attempts: ({})

    function attempt(d, kind) {
        const a = Object.assign({}, attempts);
        a[d.address] = kind;
        attempts = a;
    }

    function clearAttempt(d) {
        if (!(d.address in attempts))
            return "";
        const a = Object.assign({}, attempts);
        const k = a[d.address];
        delete a[d.address];
        attempts = a;
        return k;
    }

    // Emparejado: conectar o desconectar. Sin emparejar: emparejar o, si ya está en curso, cancelar.
    function activate(d) {
        if (d.pairing) {
            clearAttempt(d);
            d.cancelPair();
        } else if (d.paired || d.bonded) {
            if (d.connected) {
                d.disconnect();
            } else {
                d.trusted = true;   // así vuelve a conectarse solo
                attempt(d, "connect");
                d.connect();
            }
        } else {
            attempt(d, "pair");
            d.pair();
        }
    }

    function forget(d) {
        d.forget();
    }

    function rename(d, name) {
        d.name = name.trim();
    }

    // ── Avisos y seguimiento de cada dispositivo ──
    property var lowNotified: ({})

    function notify(body) {
        Quickshell.execDetached(["notify-send", "-a", "Bluetooth", "-i", "bluetooth", body]);
    }

    function checkBattery(d) {
        const low = d.connected && d.batteryAvailable && percent(d) < cfg.lowBattery;
        if (low && !lowNotified[d.address]) {
            lowNotified[d.address] = true;
            notify(d.name + ": batería baja (" + percent(d) + " %)");
        } else if (!d.connected) {
            delete lowNotified[d.address];
        }
    }

    Instantiator {
        model: store.allDevices
        delegate: QtObject {
            id: track
            required property var modelData

            property Connections conn: Connections {
                target: track.modelData

                function onConnectedChanged() {
                    const d = track.modelData;
                    if (d.connected)
                        store.clearAttempt(d);
                    if (store.armed)
                        store.notify(d.name + (d.connected ? " conectado" + (d.batteryAvailable ? " · " + store.percent(d) + " %" : "") : " desconectado"));
                    store.checkBattery(d);
                }
                function onBatteryChanged() {
                    store.checkBattery(track.modelData);
                }
                // Conectar que vuelve a Desconectado sin llegar a Conectado: falló
                function onStateChanged() {
                    const d = track.modelData;
                    if (d.state === BluetoothDeviceState.Disconnected && store.attempts[d.address] === "connect") {
                        store.clearAttempt(d);
                        store.say("No se pudo conectar");
                    }
                }
                function onPairedChanged() {
                    const d = track.modelData;
                    if (d.paired && store.clearAttempt(d) === "pair") {
                        d.trusted = true;
                        d.connect();
                    }
                }
                function onPairingChanged() {
                    const d = track.modelData;
                    if (store.request && store.request.device === d.dbusPath && !d.pairing)
                        store.request = null;
                    if (!d.pairing && !d.paired && store.attempts[d.address] === "pair") {
                        store.clearAttempt(d);
                        store.say("No se pudo emparejar");
                    }
                }
            }
        }
    }

    // ── Agente de emparejamiento ──
    // request: { id, type: confirm | pin | passkey | authorize | display, device, name, passkey?, pin? } o null
    property var request: null
    property bool agentReady: false

    function onAgent(line) {
        let m;
        try {
            m = JSON.parse(line);
        } catch (err) {
            return;
        }
        if (m.type === "ready") {
            agentReady = true;
        } else if (m.type === "error") {
            agentReady = false;
            console.warn("BluetoothStore: el agente no se pudo registrar:", m.message);
        } else if (m.type === "cancel") {
            request = null;
        } else {
            request = m;
            // Si el panel está cerrado (p. ej. el celular inicia el emparejamiento), se abre
            openPanel();
        }
    }

    // Responde la pregunta actual: `value` es el PIN o el passkey escrito
    function answer(accept, value) {
        if (!request)
            return;
        if (request.id !== undefined)
            agent.write(JSON.stringify({
                id: request.id,
                accept: accept,
                value: value ?? ""
            }) + "\n");
        request = null;
    }

    Process {
        id: agent
        running: true
        stdinEnabled: true
        command: ["python3", Quickshell.shellPath("scripts/bt-agent.py")]
        stdout: SplitParser {
            onRead: line => store.onAgent(line)
        }
        onExited: {
            store.agentReady = false;
            store.request = null;
            restartTimer.restart();
        }
    }

    // Si el agente murió (se reinició bluetoothd, por ejemplo), se vuelve a registrar
    Timer {
        id: restartTimer
        interval: 3000
        onTriggered: agent.running = true
    }
}
