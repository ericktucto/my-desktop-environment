pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import "../settings/" as ST
import "../bluetooth/" as BT
import "../network/" as NS
import "../screenshot/" as SH
import "../recorder/" as RC
import "../lock/" as LK

// Sonidos del sistema (Preferencias → Sonidos): cada evento tiene su interruptor y su sonido del tema freedesktop
// (/usr/share/sounds/freedesktop/stereo). Se reproducen con pw-play. Todo es por eventos, sin polling.
Singleton {
    id: store

    readonly property string dir: "/usr/share/sounds/freedesktop/stereo/"
    readonly property var cfg: ST.SettingsStore.sounds

    // Sonidos del tema que se pueden elegir
    readonly property var themeSounds: ["alarm-clock-elapsed", "bell", "camera-shutter", "complete", "device-added", "device-removed", "dialog-error", "dialog-information", "dialog-warning", "message", "message-new-instant", "network-connectivity-established", "network-connectivity-lost", "phone-incoming-call", "power-plug", "power-unplug", "screen-capture", "service-login", "service-logout", "window-attention"]

    // Eventos: { id, group, label, sound (el de fábrica), on (encendido de fábrica) }
    readonly property var events: [
        { id: "notify", group: "Notificaciones", label: "Notificación", sound: "message-new-instant", on: true },
        { id: "notifyUrgent", group: "Notificaciones", label: "Notificación urgente", sound: "dialog-warning", on: true },
        { id: "monitorAdded", group: "Dispositivos", label: "Monitor conectado", sound: "device-added", on: true },
        { id: "monitorRemoved", group: "Dispositivos", label: "Monitor desconectado", sound: "device-removed", on: true },
        { id: "usbAdded", group: "Dispositivos", label: "USB conectado", sound: "device-added", on: true },
        { id: "usbRemoved", group: "Dispositivos", label: "USB quitado", sound: "device-removed", on: true },
        { id: "btConnected", group: "Dispositivos", label: "Bluetooth conectado", sound: "device-added", on: true },
        { id: "btDisconnected", group: "Dispositivos", label: "Bluetooth desconectado", sound: "device-removed", on: true },
        { id: "plugged", group: "Energía", label: "Cargador conectado", sound: "power-plug", on: true },
        { id: "unplugged", group: "Energía", label: "Cargador desconectado", sound: "power-unplug", on: true },
        { id: "batteryLow", group: "Energía", label: "Batería baja", sound: "dialog-warning", on: true },
        { id: "batteryCritical", group: "Energía", label: "Batería crítica", sound: "dialog-error", on: true },
        { id: "screenshot", group: "Acciones", label: "Captura de pantalla", sound: "camera-shutter", on: true },
        { id: "recStart", group: "Acciones", label: "Grabación iniciada", sound: "service-login", on: true },
        { id: "recEnd", group: "Acciones", label: "Grabación terminada", sound: "complete", on: true },
        { id: "lock", group: "Acciones", label: "Pantalla bloqueada", sound: "service-logout", on: false },
        { id: "unlock", group: "Acciones", label: "Pantalla desbloqueada", sound: "service-login", on: false },
        { id: "netUp", group: "Acciones", label: "Red conectada", sound: "network-connectivity-established", on: false },
        { id: "netDown", group: "Acciones", label: "Red perdida", sound: "network-connectivity-lost", on: false }
    ]

    function eventOf(id) {
        return events.find(e => e.id === id) ?? null;
    }

    // Lo guardado de un evento: { on, sound } (lo que falta sale del de fábrica)
    function isOn(id) {
        const e = eventOf(id);
        const s = cfg.events[id];
        return s && s.on !== undefined ? s.on : (e?.on ?? false);
    }

    function soundOf(id) {
        const e = eventOf(id);
        const s = cfg.events[id];
        return s && s.sound ? s.sound : (e?.sound ?? "");
    }

    function setOn(id, on) {
        patch(id, { on: on });
    }

    function setSound(id, name) {
        patch(id, { sound: name });
    }

    // Se reasigna el objeto entero para que se guarde
    function patch(id, fields) {
        const all = Object.assign({}, cfg.events);
        all[id] = Object.assign({}, all[id] ?? {}, fields);
        cfg.events = all;
    }

    function resetEvent(id) {
        const all = Object.assign({}, cfg.events);
        delete all[id];
        cfg.events = all;
    }

    // ── Reproducir ──
    // Cada evento a lo más una vez por segundo (Hyprland avisa dos veces de un monitor)
    property var last: ({})

    function playFile(name) {
        if (name === "")
            return;
        const path = name.startsWith("/") ? name : dir + name + ".oga";
        Quickshell.execDetached(["pw-play", "--volume", String(Math.max(0, Math.min(1, cfg.volume))), path]);
    }

    function play(id) {
        if (!cfg.enabled || !isOn(id))
            return;
        const now = Date.now();
        if (now - (last[id] ?? 0) < 1000)
            return;
        last[id] = now;
        playFile(soundOf(id));
    }

    // Una notificación nueva: urgente o normal. NotificationStore ya descarta las normales con No molestar; los
    // avisos de batería suenan por su cuenta.
    function playNotification(urgent, app) {
        if (app === "Batería")
            return;
        play(urgent ? "notifyUrgent" : "notify");
    }

    // ── Eventos del sistema ──
    // Hasta que pasa un momento desde el arranque los cambios no cuentan (los servicios dan su estado real tarde)
    property bool ready: false
    Timer {
        running: true
        interval: 6000
        onTriggered: store.ready = true
    }

    Connections {
        target: UPower
        function onOnBatteryChanged() {
            if (store.ready)
                store.play(UPower.onBattery ? "unplugged" : "plugged");
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!store.ready)
                return;
            if (event.name.startsWith("monitoradded"))
                store.play("monitorAdded");
            else if (event.name.startsWith("monitorremoved"))
                store.play("monitorRemoved");
        }
    }

    // Bluetooth y red: por el cambio en la cantidad de dispositivos conectados / en línea
    property int btCount: BT.BluetoothStore.connected.length
    onBtCountChanged: {
        if (!ready)
            return;
        if (btCount > btPrev)
            play("btConnected");
        else if (btCount < btPrev)
            play("btDisconnected");
        btPrev = btCount;
    }
    property int btPrev: BT.BluetoothStore.connected.length

    readonly property bool online: NS.NetworkStore.online
    onOnlineChanged: {
        if (ready)
            play(online ? "netUp" : "netDown");
    }

    readonly property string shotPhase: SH.ScreenshotStore.phase
    onShotPhaseChanged: {
        if (ready && shotPhase === "saving")
            play("screenshot");
    }

    readonly property string recPhase: RC.RecorderStore.phase
    onRecPhaseChanged: {
        if (!ready)
            return;
        if (recPhase === "recording")
            play("recStart");
        else if (recPhase === "saving")
            play("recEnd");
    }

    readonly property bool locked: LK.LockStore.locked
    onLockedChanged: {
        if (ready)
            play(locked ? "lock" : "unlock");
    }

    // USB: udevadm avisa de cada dispositivo (no de sus interfaces: «1-2» y no «1-2:1.0»)
    Process {
        running: true
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=usb"]
        stdout: SplitParser {
            onRead: line => {
                if (!store.ready || !/\/\d+-[\d.]+ \(usb\)$/.test(line))
                    return;
                if (/\] add /.test(line))
                    store.play("usbAdded");
                else if (/\] remove /.test(line))
                    store.play("usbRemoved");
            }
        }
    }

    // qs ipc call stixshell@sound play <evento> · test <evento> (suena aunque esté apagado)
    IpcHandler {
        target: "stixshell@sound"
        function play(id: string): void {
            store.play(id);
        }
        function test(id: string): void {
            store.playFile(store.soundOf(id));
        }
    }
}
