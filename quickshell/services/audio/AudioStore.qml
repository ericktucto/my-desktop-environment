pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: store

    // ── Dispositivos ──
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && n.isSink)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && !n.isSink)

    // ── Permitir más del 100% (hasta 150%) ──
    // Se enciende solo si el volumen real ya supera el 100%. No se guarda entre reinicios.
    property bool allowOverSink: false
    property bool allowOverSource: false

    readonly property real normalMax: 1.0
    readonly property real boostMax: 1.5

    // Sin tracker, los nodos no exponen volume/muted
    PwObjectTracker {
        objects: store.sinks.concat(store.sources)
    }

    Connections {
        target: store.sink ? store.sink.audio : null
        function onVolumeChanged() {
            if (store.sink.audio.volume > store.normalMax + 0.001)
                store.allowOverSink = true;
        }
    }
    Connections {
        target: store.source ? store.source.audio : null
        function onVolumeChanged() {
            if (store.source.audio.volume > store.normalMax + 0.001)
                store.allowOverSource = true;
        }
    }

    // ── Teclas multimedia (hypr/keybinds/media.lua llama a esto por IPC) ──
    // qs ipc call stixshell@audio up|down|mute|micMute
    IpcHandler {
        target: "stixshell@audio"
        function up(): void {
            store.step(store.sink, store.keyStep);
        }
        function down(): void {
            store.step(store.sink, -store.keyStep);
        }
        function mute(): void {
            store.toggleMute(store.sink);
        }
        function micMute(): void {
            store.toggleMute(store.source);
        }
    }

    // Paso de las teclas de volumen (el mismo de la rueda sobre la pill)
    readonly property real keyStep: 0.05

    // ── Helpers ──
    function isDefault(node) {
        return node === store.sink || node === store.source;
    }

    // Nombre corto ("Speaker") y, si no existe, el nombre completo
    function label(node) {
        if (!node)
            return "";
        return node.properties["device.profile.description"] || node.description || node.nickname || node.name;
    }

    function allowOver(node) {
        return node === store.sink ? store.allowOverSink : store.allowOverSource;
    }

    function maxFor(node) {
        return allowOver(node) ? boostMax : normalMax;
    }

    function percent(node) {
        if (!Pipewire.ready || !node || !node.audio)
            return "--";
        return Math.round(node.audio.volume * 100);
    }

    // Ícono del parlante: off = mute, none = 0, low = hasta 50%, on = más de 50%
    function volumeIcon(node) {
        if (!node || !node.audio)
            return "volumen-none";
        if (node.audio.muted)
            return "volumen-off";
        if (node.audio.volume <= 0.001)
            return "volumen-none";
        return node.audio.volume <= 0.5 ? "volumen-low" : "volumen-on";
    }

    // Ícono del micrófono: off si está silenciado
    function micIcon(node) {
        return node && node.audio && node.audio.muted ? "microphone-off" : "microphone-on";
    }

    // ── Acciones ──
    function setVolume(node, v) {
        if (!node || !node.audio)
            return;
        node.audio.volume = Math.max(0, Math.min(maxFor(node), v));
        // Auto-unmute al mover el volumen
        if (node.audio.muted)
            node.audio.muted = false;
    }

    function step(node, delta) {
        if (!node || !node.audio)
            return;
        setVolume(node, node.audio.volume + delta);
    }

    function toggleMute(node) {
        if (node && node.audio)
            node.audio.muted = !node.audio.muted;
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    function setAllowOver(isSink, on) {
        if (isSink)
            allowOverSink = on;
        else
            allowOverSource = on;

        const node = isSink ? sink : source;
        if (!on && node && node.audio && node.audio.volume > normalMax)
            node.audio.volume = normalMax;
    }
}
