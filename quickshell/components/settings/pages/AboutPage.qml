import QtQuick
import Quickshell
import Quickshell.Io
import "../rows/" as R
import "../../../services/settings/" as ST
import "../../../" as App

// Acerca de: versiones, las herramientas que usa la shell (cuáles faltan) y accesos a los archivos de datos.
Page {
    id: page

    // [comando, para qué sirve]
    readonly property var tools: [
        ["hyprctl", "Base (Hyprland)"],
        ["brightnessctl", "Brillo"],
        ["upower", "Batería"],
        ["powerprofilesctl", "Perfiles de energía"],
        ["notify-send", "Avisos (libnotify)"],
        ["hypridle", "Inactividad"],
        ["hyprlock", "Bloqueo de respaldo"],
        ["hyprsunset", "Luz nocturna"],
        ["cliphist", "Historial del portapapeles"],
        ["wl-copy", "Copiar (wl-clipboard)"],
        ["wtype", "Escribir en la ventana"],
        ["grim", "Capturador de pantalla"],
        ["wf-recorder", "Grabador de pantalla"],
        ["matugen", "Colores del wallpaper"],
        ["hyprpicker", "Gotero de color"],
        ["pw-play", "Sonidos"],
        ["playerctl", "Multimedia (respaldo)"],
        ["nmcli", "Red (NetworkManager)"],
        ["bluetoothctl", "Bluetooth"],
        ["kitty", "Terminal"],
        ["python3", "Scripts de la shell"]
    ]
    // Resultado: { cmd, what, ok }
    property var found: []
    property string qsVersion: "…"
    property string hyprVersion: "…"

    pageId: "about"
    pageName: "Acerca de"
    subtitle: "Versiones, herramientas y archivos de la shell."

    // Se vuelve a mirar cada vez que se abre la página
    readonly property bool shown: ST.SettingsUi.open && ST.SettingsUi.page === pageId
    onShownChanged: {
        if (shown && !probe.running) {
            probe.running = true;
        }
    }

    Process {
        id: probe
        command: ["sh", "-c", 'qs --version 2>/dev/null | head -1; echo "--"; hyprctl version 2>/dev/null | head -1; echo "--"; for c in "$@"; do if command -v "$c" >/dev/null 2>&1; then echo "ok $c"; else echo "no $c"; fi; done', "_"].concat(page.tools.map(t => t[0]))
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("--\n");
                page.qsVersion = (parts[0] ?? "").trim().replace(/ \(revision.*$/, "") || "no se pudo leer";
                page.hyprVersion = (parts[1] ?? "").trim().replace(/ built from.*$/, "") || "no se pudo leer";
                const ok = {};
                (parts[2] ?? "").split("\n").forEach(l => {
                    const m = /^(ok|no) (.+)$/.exec(l);
                    if (m)
                        ok[m[2]] = m[1] === "ok";
                });
                page.found = page.tools.map(t => ({
                            cmd: t[0],
                            what: t[1],
                            ok: ok[t[0]] === true
                        }));
            }
        }
    }

    function openTerminal(args) {
        Quickshell.execDetached(["kitty"].concat(args));
    }

    R.Section {
        text: "Versiones"
    }
    R.InfoRow {
        searchId: "versionQs"
        label: "Quickshell"
        keywords: "version"
        value: page.qsVersion
    }
    R.InfoRow {
        searchId: "versionHypr"
        label: "Hyprland"
        keywords: "version"
        value: page.hyprVersion
    }

    R.Section {
        text: "Archivos"
    }
    R.ActionRow {
        searchId: "openSettings"
        label: "Abrir settings.json"
        hint: ST.SettingsStore.filePath
        keywords: "ajustes archivo editar json"
        actionLabel: "Abrir"
        onTriggered: page.openTerminal(["sh", "-c", 'exec "${EDITOR:-nvim}" "$1"', "_", ST.SettingsStore.filePath])
    }
    R.ActionRow {
        searchId: "openLog"
        label: "Ver el registro de la shell"
        hint: "qs log, en una terminal."
        keywords: "log errores avisos"
        actionLabel: "Abrir"
        onTriggered: page.openTerminal(["--hold", "sh", "-c", "qs log | less -R +G"])
    }
    R.ActionRow {
        searchId: "openDataDir"
        label: "Abrir la carpeta de datos"
        hint: ST.SettingsStore.dir
        keywords: "carpeta stixshell tareas temporizadores"
        actionLabel: "Abrir"
        onTriggered: Quickshell.execDetached(["xdg-open", ST.SettingsStore.dir])
    }

    R.Section {
        text: "Herramientas"
    }
    Repeater {
        model: page.found
        R.InfoRow {
            required property var modelData
            label: modelData.what
            hint: modelData.cmd
            value: modelData.ok ? "Instalada" : "Falta"
            valueColor: modelData.ok ? App.Theme.green : App.Theme.amber
        }
    }
}
