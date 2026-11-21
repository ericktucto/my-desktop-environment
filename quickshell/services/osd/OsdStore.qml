pragma Singleton
import QtQuick
import Quickshell
import "../settings/" as ST
import "../../" as App

// Qué muestra el OSD de la isla central contraída: "", "volume", "brightness", "mic" o "nightlight".
Singleton {
    id: store

    property string kind: ""

    // ── Estirado en el tope: la isla crece al seguir pulsando con el nivel al máximo (o mínimo) ──
    property real excess: 0
    property int edgeDir: 0
    readonly property real stretch: {
        const m = App.Config.osd.edgeMax;
        return m * (1 - 1 / (1 + App.Config.osd.edgeResistance * excess / m));
    }

    function edge(dir) {
        if (ST.SettingsStore.appearance.animations === false) {
            show(kind);
            return;
        }
        excess = dir === edgeDir ? excess + App.Config.osd.edgeStep : App.Config.osd.edgeStep;
        edgeDir = dir;
        edgeTimer.restart();
    }

    function settle() {
        excess = 0;
        edgeDir = 0;
        edgeTimer.stop();
    }

    Timer {
        id: edgeTimer
        interval: App.Config.osd.edgeHold
        onTriggered: store.settle()
    }

    function show(k) {
        kind = k;
        hideTimer.restart();
    }

    function hide() {
        kind = "";
        settle();
        hideTimer.stop();
    }

    Timer {
        id: hideTimer
        interval: App.Config.osd.timeout
        onTriggered: {
            store.kind = "";
            store.settle();
        }
    }
}
