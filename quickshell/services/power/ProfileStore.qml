pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../settings/" as ST
import "../../" as App

// Perfiles de energía (power-profiles-daemon): uno con batería y otro con cargador.
Singleton {
    id: store

    // Los nombres (`key`) son los de `powerprofilesctl`, y los que se guardan en settings.json
    readonly property var all: [
        {
            key: "power-saver",
            value: PowerProfile.PowerSaver,
            label: "Ahorro",
            glyph: 0xf032a,
            color: App.Theme.green
        },
        {
            key: "balanced",
            value: PowerProfile.Balanced,
            label: "Equilibrado",
            glyph: 0xf05d1,
            color: App.Theme.primary
        },
        {
            key: "performance",
            value: PowerProfile.Performance,
            label: "Rendimiento",
            glyph: 0xf14de,
            color: App.Theme.orange
        }
    ]

    // Sin perfil de rendimiento (algunos equipos no lo tienen), solo los otros dos
    readonly property var choices: all.filter(p => p.key !== "performance" || PowerProfiles.hasPerformanceProfile)

    readonly property int profile: PowerProfiles.profile
    // El daemon responde (si no, el panel oculta los perfiles)
    property bool available: false

    function byKey(key) {
        return all.find(p => p.key === key) || null;
    }

    function byValue(value) {
        return all.find(p => p.value === value) || all[1];
    }

    function set(value) {
        if (available)
            PowerProfiles.profile = value;
    }

    // ── Avisos del daemon ──
    readonly property string degradedText: {
        switch (PowerProfiles.degradationReason) {
        case PerformanceDegradationReason.HighTemperature:
            return "Rendimiento limitado: temperatura alta";
        case PerformanceDegradationReason.LapDetected:
            return "Rendimiento limitado: equipo sobre las piernas";
        default:
            return "";
        }
    }

    // ── Perfil de la fuente actual: uno con batería y otro con cargador ──
    readonly property bool onBattery: UPower.onBattery

    readonly property string wantedKey: {
        const k = onBattery ? ST.SettingsStore.profiles.battery : ST.SettingsStore.profiles.ac;
        // Rendimiento guardado pero el equipo no lo tiene: Equilibrado
        return k === "performance" && !PowerProfiles.hasPerformanceProfile ? "balanced" : k;
    }
    readonly property var wanted: wantedNow()

    // Se calcula al momento: dentro de onWantedKeyChanged, `wanted` aún tiene el valor anterior
    function wantedNow() {
        return byKey(wantedKey) || all[1];
    }

    function apply() {
        if (!available)
            return;
        PowerProfiles.profile = wantedNow().value;
    }

    // Se aplica al arrancar, al enchufar o desenchufar, y al cambiar en el panel la fila de la fuente actual.
    // UPower tarda un momento en dar la fuente real al arrancar: hasta entonces los cambios no cuentan y
    // el temporizador aplica el perfil final una sola vez.
    property bool armed: false
    Timer {
        interval: 3000
        running: true
        onTriggered: {
            store.armed = true;
            store.apply();
        }
    }
    onWantedKeyChanged: {
        if (armed)
            apply();
    }
    onAvailableChanged: {
        if (armed && available)
            apply();
    }

    // Si algo cambió el perfil por fuera (Fn+Q, powerprofilesctl, una app), se respeta hasta el próximo
    // cambio de fuente y se avisa
    readonly property string overrideText: {
        if (!available || PowerProfiles.profile === wanted.value)
            return "";
        const now = byValue(PowerProfiles.profile).label;
        const h = PowerProfiles.holds;
        if (h && h.length > 0)
            return "Ahora: " + now + " (lo pidió " + h[0].applicationId + ")";
        return "Ahora: " + now + " (cambiado fuera del panel, p. ej. Fn+Q)";
    }

    // ¿Responde el daemon? Si `powerprofilesctl get` funciona, sí.
    function refresh() {
        probe.running = true;
    }

    Process {
        id: probe
        running: true
        command: ["powerprofilesctl", "get"]
        onExited: function (code) {
            store.available = code === 0;
        }
    }
}
