pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../session/" as S
import "../settings/" as ST
import "../../" as App

// Estado de la batería (texto para el panel) y avisos de batería baja.
Singleton {
    id: store

    readonly property var device: UPower.displayDevice
    readonly property int percent: Math.round((device?.percentage ?? 0) * 100)
    readonly property bool charging: device?.state === UPowerDeviceState.Charging
    readonly property bool full: device?.state === UPowerDeviceState.FullyCharged
    readonly property bool discharging: device?.state === UPowerDeviceState.Discharging

    readonly property string stateText: {
        if (full)
            return "Cargada";
        if (charging) {
            const t = device.timeToFull;
            return t > 0 ? "Cargando · llena en " + ST.SettingsStore.format(Math.round(t / 60) * 60) : "Cargando";
        }
        if (discharging) {
            const t = device.timeToEmpty;
            return t > 0 ? "Con batería · quedan " + ST.SettingsStore.format(Math.round(t / 60) * 60) : "Con batería";
        }
        return conservation ? "Conectada · modo conservación" : "Conectada";
    }

    // ── Modo conservación (IdeaPad): limita la carga a ~60 % para cuidar la batería ──
    // sysfs no avisa los cambios, así que se vuelve a leer al abrir el panel y al escribir.
    property string conservationPath: ""
    property bool conservation: false
    property bool conservationWritable: false
    readonly property bool conservationAvailable: conservationPath !== ""

    function refreshConservation() {
        conservationProc.running = true;
    }

    function setConservation(on) {
        if (!conservationAvailable || !conservationWritable)
            return;
        conservationSet.command = ["sh", "-c", 'echo "$1" > "$2"', "_", on ? "1" : "0", conservationPath];
        conservationSet.running = true;
    }

    Process {
        id: conservationProc
        // línea 1: ruta · línea 2: valor · línea 3: w si se puede escribir
        command: ["sh", "-c", 'p=$(ls -d /sys/bus/platform/drivers/ideapad_acpi/VPC2004:*/conservation_mode 2>/dev/null | head -1); [ -n "$p" ] || exit 0; echo "$p"; cat "$p"; [ -w "$p" ] && echo w || echo r']
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                store.conservationPath = l[0] || "";
                store.conservation = l[1] === "1";
                store.conservationWritable = l[2] === "w";
            }
        }
    }

    Process {
        id: conservationSet
        onExited: store.refreshConservation()
    }

    readonly property string rateText: {
        const r = Math.abs(device?.changeRate ?? 0);
        return r > 0 ? r.toFixed(1).replace(".", ",") + " W" : "";
    }

    // Batería física (la salud solo la da ella)
    readonly property var battery: UPower.devices.values.find(d => d.isLaptopBattery)
    readonly property string healthText: battery && battery.healthSupported ? "Salud " + Math.round(battery.healthPercentage) + " %" : ""

    readonly property string detailText: [rateText, healthText].filter(t => t !== "").join(" · ")

    // ── Avisos de batería baja ──
    // Cada umbral avisa una sola vez al cruzarlo hacia abajo y se rearma al cargar o al subir.
    property var fired: ({
            warn: false,
            critical: false,
            suspend: false
        })

    function notify(urgency, title, body) {
        Quickshell.execDetached(["notify-send", "-u", urgency, "-a", "Batería", "-i", urgency === "critical" ? "battery-caution" : "battery-low", title, body]);
    }

    function check() {
        if (!device)
            return;
        const low = ST.SettingsStore.low;
        const levels = [["warn", low.warn], ["critical", low.critical], ["suspend", low.suspend]];
        const f = Object.assign({}, fired);
        for (const [key, limit] of levels) {
            if (limit <= 0 || charging || full || percent > limit) {
                f[key] = false;
                continue;
            }
            if (!discharging || f[key])
                continue;
            f[key] = true;
            if (key === "warn")
                notify("normal", "Batería baja", percent + " % restante");
            else if (key === "critical")
                notify("critical", "Batería crítica", percent + " % restante. Conecta el cargador.");
            else {
                notify("critical", "Batería casi agotada", "Suspendiendo en " + Math.round(App.Config.idle.lowBatterySuspendDelay / 1000) + " s…");
                suspendTimer.restart();
            }
        }
        fired = f;
        // Enchufar el cargador cancela la suspensión pendiente
        if (!discharging)
            suspendTimer.stop();
    }

    // Cambiar un umbral también vuelve a evaluar los avisos
    readonly property int warnLimit: ST.SettingsStore.low.warn
    readonly property int criticalLimit: ST.SettingsStore.low.critical
    readonly property int suspendLimit: ST.SettingsStore.low.suspend
    onWarnLimitChanged: check()
    onCriticalLimitChanged: check()
    onSuspendLimitChanged: check()

    onPercentChanged: check()
    onChargingChanged: check()
    onDischargingChanged: check()
    onFullChanged: check()
    Component.onCompleted: {
        check();
        refreshConservation();
    }

    Timer {
        id: suspendTimer
        interval: App.Config.idle.lowBatterySuspendDelay
        onTriggered: {
            if (store.discharging && store.percent <= ST.SettingsStore.low.suspend)
                S.SessionStore.exec(["loginctl", "suspend"]);
        }
    }
}
