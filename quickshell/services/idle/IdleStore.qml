pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import "../brightness/" as B
import "../lock/" as L
import "../media/" as MD
import "../session/" as S
import "../settings/" as ST
import "../../" as App

// Inactividad: atenúa, bloquea, apaga la pantalla y suspende, con tiempos distintos
// con batería y con cargador (Config.idle). Respeta los inhibidores (videos, etc.).
Singleton {
    id: store

    readonly property bool onBattery: UPower.onBattery
    // Tiempos y nivel de atenuado: los del usuario (ST.SettingsStore), con Config.qml de base
    readonly property var cfg: onBattery ? ST.SettingsStore.idle.battery : ST.SettingsStore.idle.ac
    readonly property real dimLevel: ST.SettingsStore.idle.dimLevel

    // Modo cafeína: no atenuar, bloquear, apagar la pantalla ni suspender (no se guarda)
    property bool caffeine: false

    function toggleCaffeine() {
        caffeine = !caffeine;
        if (caffeine)
            undim();
    }

    // Brillo guardado mientras la pantalla está atenuada (-1 = no atenuada)
    property real savedBrightness: -1

    function dpms(on) {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.dpms({ action = \"" + (on ? "on" : "off") + "\" })"]);
    }

    function dim() {
        if (savedBrightness >= 0)
            return;
        savedBrightness = B.BrightnessStore.value;
        B.BrightnessStore.set(dimLevel);
    }

    function undim() {
        if (savedBrightness < 0)
            return;
        B.BrightnessStore.set(savedBrightness);
        savedBrightness = -1;
    }

    IdleMonitor {
        id: dimMonitor
        timeout: store.cfg.dim
        enabled: store.cfg.dim > 0 && !L.LockStore.locked && !store.caffeine
        respectInhibitors: true
        onIsIdleChanged: isIdle ? store.dim() : store.undim()
    }

    IdleMonitor {
        timeout: store.cfg.lock
        enabled: store.cfg.lock > 0 && !store.caffeine
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle) {
                L.LockStore.lock();
                store.undim();
            }
        }
    }

    IdleMonitor {
        timeout: store.cfg.screenOff
        enabled: store.cfg.screenOff > 0 && !store.caffeine
        respectInhibitors: true
        onIsIdleChanged: store.dpms(!isIdle)
    }

    IdleMonitor {
        timeout: store.cfg.suspend
        // Mientras suena música no se suspende (sí se atenúa, bloquea y apaga la pantalla)
        enabled: store.cfg.suspend > 0 && !store.caffeine && !MD.MediaStore.anyPlaying
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                S.SessionStore.exec(["loginctl", "suspend"]);
        }
    }
}
