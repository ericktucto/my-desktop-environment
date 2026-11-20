import QtQuick
import "../rows/" as R
import "../../../services/display/" as D
import "../../../services/settings/" as ST
import "../../../" as App

// Pantallas: modo rápido (espejo, extender…), y por monitor la resolución, la frecuencia, la escala, la
// rotación, el encendido y el espejo. Cada cambio se aplica en vivo y pide confirmar en 15 s o se revierte.
Page {
    id: page

    readonly property var store: D.DisplayStore
    readonly property var monitors: store.monitors
    readonly property bool pending: store.pending !== null

    readonly property var scales: [
        { id: "1", label: "100 %" },
        { id: "1.25", label: "125 %" },
        { id: "1.5", label: "150 %" },
        { id: "1.75", label: "175 %" },
        { id: "2", label: "200 %" }
    ]
    readonly property var rotations: [
        { id: "0", label: "Normal" },
        { id: "1", label: "90°" },
        { id: "2", label: "180°" },
        { id: "3", label: "270°" }
    ]
    readonly property var quickModes: [
        { id: "mirror", label: "Espejo" },
        { id: "extend", label: "Extender" },
        { id: "external", label: "Solo externo" },
        { id: "laptop", label: "Solo portátil" }
    ]

    pageId: "displays"
    pageName: "Pantallas"
    subtitle: monitors.length === 1 ? "1 pantalla conectada." : monitors.length + " pantallas conectadas."

    // Se vuelve a leer al abrir la página
    readonly property bool shown: ST.SettingsUi.open && ST.SettingsUi.page === pageId
    onShownChanged: {
        if (shown)
            store.refresh();
    }

    // Cambia un monitor y espera la confirmación
    function change(m, patch) {
        const c = Object.assign(store.configOf(m), patch);
        const cfg = {};
        cfg[m.name] = c;
        store.tryConfig(cfg);
    }

    function resolutions(m) {
        const seen = [];
        m.modes.forEach(o => {
            const id = o.w + "x" + o.h;
            if (!seen.includes(id))
                seen.push(id);
        });
        return seen.map(id => ({
                    id: id,
                    label: id.replace("x", " × ")
                }));
    }

    function refreshes(m) {
        return m.modes.filter(o => o.w === m.width && o.h === m.height).map(o => ({
                    id: o.text.replace("Hz", ""),
                    label: o.hz.toFixed(o.hz % 1 < 0.05 ? 0 : 2).replace(/\.00$/, "") + " Hz"
                }));
    }

    function currentModeId(m) {
        return store.configOf(m).mode;
    }

    // ── Confirmación ──
    R.InfoRow {
        visible: page.pending
        label: "¿Mantener esta configuración?"
        hint: "Se revierte sola en " + page.store.countdown + " s."
        value: ""
    }
    R.ActionRow {
        visible: page.pending
        label: "Mantener"
        actionLabel: "Mantener"
        primary: true
        onTriggered: page.store.keep()
    }
    R.ActionRow {
        visible: page.pending
        label: "Revertir"
        actionLabel: "Revertir"
        onTriggered: page.store.revert()
    }

    // ── Disposición (a escala) ──
    Item {
        visible: page.monitors.length > 1
        width: parent.width
        height: 130
        readonly property real extentW: Math.max(1, Math.max.apply(null, page.monitors.map(m => (m.x + m.width / m.scale))))
        readonly property real extentH: Math.max(1, Math.max.apply(null, page.monitors.map(m => (m.y + m.height / m.scale))))
        readonly property real k: Math.min((width - 40) / extentW, (height - 20) / extentH)

        Repeater {
            model: page.monitors
            Rectangle {
                required property var modelData
                x: 20 + modelData.x * parent.k
                y: 10 + modelData.y * parent.k
                width: modelData.width / modelData.scale * parent.k
                height: modelData.height / modelData.scale * parent.k
                radius: 6
                color: modelData.disabled ? "transparent" : App.Theme.surfaceActive
                border.width: 1
                border.color: modelData.mirrorOf !== "none" ? App.Theme.primary : App.Theme.islandEdge
                Text {
                    anchors.centerIn: parent
                    text: modelData.name
                    color: modelData.disabled ? App.Theme.grayDark : App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                }
            }
        }
    }

    // ── Modo rápido ──
    R.ChoiceRow {
        visible: page.store.laptop !== null && page.store.externals.length > 0
        searchId: "displayMode"
        label: "Modo"
        hint: "Con un monitor externo: espejo, extender o usar solo uno."
        keywords: "hdmi proyector duplicar espejo extender monitor externo"
        options: page.quickModes
        value: page.store.currentMode
        onPicked: id => {
            const c = page.store.modeConfig(id);
            if (c)
                page.store.tryConfig(c);
        }
    }

    R.SwitchRow {
        searchId: "displayAuto"
        label: "Perfiles automáticos"
        hint: "Al conectar o quitar un monitor se aplica la configuración que guardaste para ese conjunto."
        keywords: "hdmi conectar monitor perfil kanshi"
        checked: ST.SettingsStore.displays.auto
        defaultValue: true
        onToggled: c => ST.SettingsStore.displays.auto = c
    }
    R.InfoRow {
        label: "Super+Shift+P"
        hint: "Pasa por espejo, extender, solo externo y solo portátil."
        value: ""
    }

    // ── Cada monitor ──
    Repeater {
        model: page.monitors
        Column {
            id: mon
            required property var modelData
            width: page.width - 16
            spacing: 8

            R.Section {
                text: mon.modelData.name + " · " + mon.modelData.description
            }
            R.SwitchRow {
                visible: page.monitors.filter(x => !x.disabled).length > 1 || mon.modelData.disabled
                searchId: "display-on-" + mon.modelData.name
                label: "Encendida"
                hint: mon.modelData.name
                keywords: "pantalla monitor apagar activar"
                checked: !mon.modelData.disabled
                defaultValue: true
                onToggled: c => page.change(mon.modelData, {
                        disabled: !c
                    })
            }
            R.CycleRow {
                visible: !mon.modelData.disabled
                searchId: "display-res-" + mon.modelData.name
                label: "Resolución"
                hint: mon.modelData.name
                keywords: "pantalla monitor tamano 1080p"
                options: page.resolutions(mon.modelData)
                value: mon.modelData.width + "x" + mon.modelData.height
                onPicked: id => {
                    // La frecuencia más alta de esa resolución
                    const opts = mon.modelData.modes.filter(o => o.w + "x" + o.h === id);
                    const best = opts.reduce((a, b) => b.hz > a.hz ? b : a, opts[0]);
                    page.change(mon.modelData, {
                        mode: best.text.replace("Hz", "")
                    });
                }
            }
            R.CycleRow {
                visible: !mon.modelData.disabled
                searchId: "display-hz-" + mon.modelData.name
                label: "Frecuencia"
                hint: mon.modelData.name
                keywords: "pantalla monitor hz refresco"
                options: page.refreshes(mon.modelData)
                value: page.currentModeId(mon.modelData)
                onPicked: id => page.change(mon.modelData, {
                        mode: id
                    })
            }
            R.CycleRow {
                visible: !mon.modelData.disabled
                searchId: "display-scale-" + mon.modelData.name
                label: "Escala"
                hint: mon.modelData.name
                keywords: "pantalla monitor tamano zoom hidpi"
                options: page.scales
                value: String(mon.modelData.scale)
                defaultValue: "1"
                onPicked: id => page.change(mon.modelData, {
                        scale: parseFloat(id)
                    })
            }
            R.CycleRow {
                visible: !mon.modelData.disabled
                searchId: "display-rot-" + mon.modelData.name
                label: "Rotación"
                hint: mon.modelData.name
                keywords: "pantalla monitor girar vertical"
                options: page.rotations
                value: String(mon.modelData.transform)
                defaultValue: "0"
                onPicked: id => page.change(mon.modelData, {
                        transform: parseInt(id)
                    })
            }
            R.CycleRow {
                visible: !mon.modelData.disabled && page.monitors.length > 1
                searchId: "display-mirror-" + mon.modelData.name
                label: "Espejo de"
                hint: mon.modelData.name
                keywords: "pantalla monitor duplicar copiar"
                options: [
                    {
                        id: "",
                        label: "Ninguno"
                    }
                ].concat(page.monitors.filter(x => x.name !== mon.modelData.name && !x.disabled).map(x => ({
                                id: x.name,
                                label: x.name
                            })))
                value: mon.modelData.mirrorOf !== "none" ? mon.modelData.mirrorOf : ""
                onPicked: id => page.change(mon.modelData, {
                        mirror: id,
                        auto: id !== ""
                    })
            }
        }
    }
}
