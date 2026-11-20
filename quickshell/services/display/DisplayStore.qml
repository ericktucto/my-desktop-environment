pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../settings/" as ST
import "../../" as App

// Pantallas: lee los monitores de Hyprland (hyprctl monitors all -j), aplica una configuración en vivo
// (hyprctl eval con hl.monitor) y la guarda: en settings.json (displays) y en ~/.config/hypr/monitors.lua,
// que hyprland.lua carga al iniciar. Sin polling: se vuelve a leer al abrir la página y con los eventos de
// monitor de Hyprland.
Singleton {
    id: store

    readonly property string luaPath: Quickshell.env("HOME") + "/.config/hypr/monitors.lua"
    readonly property var data: ST.SettingsStore.displays

    // Monitores conectados: { name, description, key, width, height, refresh, x, y, scale, transform, mirrorOf,
    // disabled, vrr, modes: [{ w, h, hz, text }] }
    property var monitors: []
    // «descripción|descripción…» del conjunto conectado (para los perfiles)
    readonly property string setKey: monitors.map(m => m.key).sort().join("|")

    // Config pendiente de confirmar: { previous, applied } y los segundos que quedan para revertir
    property var pending: null
    property int countdown: 0

    function isLaptop(m) {
        return /^(eDP|LVDS)/.test(m.name);
    }
    readonly property var laptop: monitors.find(m => isLaptop(m)) ?? null
    readonly property var externals: monitors.filter(m => !isLaptop(m))

    // ── Lectura ──
    function refresh() {
        if (!reader.running)
            reader.running = true;
    }

    Process {
        id: reader
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    store.monitors = JSON.parse(text).map(m => ({
                                name: m.name,
                                description: m.description,
                                key: m.make + " " + m.model + " " + m.serial,
                                width: m.width,
                                height: m.height,
                                refresh: m.refreshRate,
                                x: m.x,
                                y: m.y,
                                scale: m.scale,
                                transform: m.transform,
                                mirrorOf: m.mirrorOf,
                                disabled: m.disabled,
                                focused: m.focused,
                                vrr: m.vrr,
                                modes: (m.availableModes ?? []).map(s => {
                                    const r = /^(\d+)x(\d+)@([\d.]+)Hz$/.exec(s);
                                    return r ? {
                                        w: parseInt(r[1]),
                                        h: parseInt(r[2]),
                                        hz: parseFloat(r[3]),
                                        text: s
                                    } : null;
                                }).filter(x => x !== null)
                            }));
                } catch (err) {
                    store.monitors = [];
                }
            }
        }
    }

    // ── Perfiles: al cambiar el conjunto de monitores se aplica el que se guardó para ese conjunto ──
    property bool ready: false
    onSetKeyChanged: {
        if (!ready) {
            if (monitors.length > 0)
                ready = true;
            return;
        }
        const prof = data.profiles[setKey];
        if (data.auto && prof && !pending && monitors.length > 0)
            applyLive(prof);
    }

    // Conectar o quitar un monitor
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name.startsWith("monitoradded") || event.name.startsWith("monitorremoved"))
                refreshTimer.restart();
        }
    }
    Timer {
        id: refreshTimer
        interval: 600
        onTriggered: store.refresh()
    }

    Component.onCompleted: refresh()

    // ── Configuración ──
    // La de un monitor tal como está ahora: { mode, x, y, scale, transform, mirror, disabled }
    function configOf(m) {
        const cur = m.modes.find(o => o.w === m.width && o.h === m.height && Math.abs(o.hz - m.refresh) < 0.5);
        return {
            mode: cur ? cur.text.replace("Hz", "") : m.width + "x" + m.height + "@" + Math.round(m.refresh),
            x: m.x,
            y: m.y,
            scale: m.scale,
            transform: m.transform,
            mirror: m.mirrorOf !== "none" ? m.mirrorOf : "",
            disabled: m.disabled
        };
    }

    function currentConfig() {
        const out = {};
        monitors.forEach(m => out[m.name] = configOf(m));
        return out;
    }

    // hl.monitor({…}) de un monitor
    function luaFor(name, c) {
        const parts = ['output = "' + name + '"'];
        if (c.disabled) {
            parts.push("disabled = true");
        } else {
            parts.push('mode = "' + c.mode + '"');
            parts.push('position = "' + (c.auto ? "auto" : Math.round(c.x) + "x" + Math.round(c.y)) + '"');
            parts.push("scale = " + c.scale);
            parts.push("transform = " + (c.transform ?? 0));
            parts.push('mirror = "' + (c.mirror ?? "") + '"');
        }
        return "hl.monitor({ " + parts.join(", ") + " })";
    }

    // Aplica en vivo (sin guardar)
    function applyLive(cfg) {
        const lua = Object.keys(cfg).map(n => luaFor(n, cfg[n])).join("\n");
        Quickshell.execDetached(["hyprctl", "eval", lua]);
        refreshTimer.restart();
    }

    // Cambia varios monitores a la vez y espera la confirmación (15 s o se revierte)
    function tryConfig(cfg) {
        if (pending)
            return;
        pending = {
            previous: currentConfig(),
            applied: cfg
        };
        countdown = App.Config.displays.confirmSeconds;
        applyLive(cfg);
        confirmTimer.restart();
    }

    function keep() {
        if (!pending)
            return;
        save(pending.applied);
        pending = null;
        confirmTimer.stop();
    }

    function revert() {
        if (!pending)
            return;
        applyLive(pending.previous);
        pending = null;
        confirmTimer.stop();
    }

    Timer {
        id: confirmTimer
        interval: 1000
        repeat: true
        onTriggered: {
            store.countdown--;
            if (store.countdown <= 0)
                store.revert();
        }
    }

    // ── Guardado ──
    // monitors.lua con lo último de cada monitor; el perfil del conjunto conectado
    function save(cfg) {
        const all = Object.assign({}, data.monitors, cfg);
        data.monitors = all;
        const profiles = Object.assign({}, data.profiles);
        profiles[setKey] = Object.assign({}, profiles[setKey] ?? {}, cfg);
        data.profiles = profiles;
        writeLua(all);
    }

    function writeLua(all) {
        const lines = ["-- Generado por Preferencias del sistema → Pantallas. No lo edites: se vuelve a escribir."];
        Object.keys(all).forEach(n => lines.push(luaFor(n, all[n])));
        luaFile.setText(lines.join("\n") + "\n");
    }

    FileView {
        id: luaFile
        path: store.luaPath
        printErrors: false
    }

    // ── Modos rápidos (como Win+P) ──
    // "mirror": el externo copia al portátil · "extend": el externo a la derecha · "external": solo el externo ·
    // "laptop": solo el portátil. Devuelve la config o null si no aplica (sin portátil o sin externo).
    function modeConfig(mode) {
        const l = laptop;
        const e = externals[0];
        if (!l || !e)
            return null;
        const cl = configOf(l);
        const ce = configOf(e);
        // El modo preferido del externo si estaba apagado
        if (ce.disabled)
            ce.mode = "preferred";
        cl.disabled = false;
        ce.disabled = false;
        cl.mirror = "";
        ce.mirror = "";
        cl.x = 0;
        cl.y = 0;
        if (mode === "mirror") {
            ce.mirror = l.name;
            ce.auto = true;
            ce.mode = "preferred";
        } else if (mode === "extend") {
            ce.x = Math.round(l.width / l.scale);
            ce.y = 0;
        } else if (mode === "external") {
            cl.disabled = true;
            ce.x = 0;
            ce.y = 0;
        } else if (mode === "laptop") {
            ce.disabled = true;
        } else {
            return null;
        }
        const out = {};
        out[l.name] = cl;
        out[e.name] = ce;
        return out;
    }

    // Aplica un modo rápido de una vez, sin confirmar, y lo guarda (el atajo Super+Shift+P)
    function applyMode(mode) {
        const c = modeConfig(mode);
        if (!c)
            return false;
        applyLive(c);
        save(c);
        Quickshell.execDetached(["notify-send", "-a", "Pantallas", "-i", "video-display", "-t", "2500", "Pantallas", modeLabels[mode] ?? mode]);
        return true;
    }

    readonly property var modeOrder: ["mirror", "extend", "external", "laptop"]
    readonly property var modeLabels: ({
            mirror: "Espejo",
            extend: "Extender",
            external: "Solo el monitor externo",
            laptop: "Solo el portátil"
        })

    // Modo que se ve ahora
    readonly property string currentMode: {
        const l = laptop;
        const e = externals[0];
        if (!l || !e)
            return "";
        if (e.disabled)
            return "laptop";
        if (l.disabled)
            return "external";
        return e.mirrorOf !== "none" ? "mirror" : "extend";
    }

    // IPC: qs ipc call stixshell@display refresh|mode <mirror|extend|external|laptop>|cycle|keep|revert
    IpcHandler {
        target: "stixshell@display"
        function refresh(): void {
            store.refresh();
        }
        function mode(m: string): string {
            const c = store.modeConfig(m);
            if (!c)
                return "error: sin monitor externo";
            store.tryConfig(c);
            return "ok";
        }
        // La config de ahora en Lua (para ver qué se guardaría)
        function lua(): string {
            const c = store.currentConfig();
            return Object.keys(c).map(n => store.luaFor(n, c[n])).join("\n");
        }
        // El siguiente modo (espejo → extender → solo externo → solo portátil), como Win+P
        function cycle(): string {
            const i = store.modeOrder.indexOf(store.currentMode);
            return store.applyMode(store.modeOrder[(i + 1) % store.modeOrder.length]) ? "ok" : "error: sin monitor externo";
        }
        function keep(): void {
            store.keep();
        }
        function revert(): void {
            store.revert();
        }
    }
}
