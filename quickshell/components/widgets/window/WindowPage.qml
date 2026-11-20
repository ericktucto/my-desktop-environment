import QtQuick
import "../controlcenter/" as CC
import "../../../services/windows/" as WS
import "../../../services/windows/WindowMenu.js" as WM
import "../../../" as App

// Pestaña «Ventana»: mover a un workspace o al stash (chips, con su atajo debajo) y una lista tipo menú con
// el estado (flotante, fijada, maximizada…), capturar, mover al otro monitor, cerrar y forzar el cierre.
// Cada fila lleva su atajo de Hyprland (Config.activeWindow.hyprKeys). Cada acción cierra la isla.
Column {
    id: root

    readonly property var store: WS.ActiveWindowStore
    readonly property var info: store.info
    readonly property var cfg: App.Config.activeWindow
    readonly property bool floating: info.floating === true
    readonly property bool inStash: (info.workspace?.name ?? "") === "special:stash"
    // «Forzar cierre» espera un segundo clic
    property bool killArmed: false

    // Acciones de la lista, en el orden en que se ven (el teclado recorre las mismas)
    readonly property var entries: {
        const k = cfg.hyprKeys;
        const list = [
            {
                id: "float",
                label: "Flotante",
                keys: k.float,
                checked: floating,
                run: () => store.toggleFloat()
            },
            {
                id: "pin",
                label: "Fijar",
                keys: k.pin,
                checked: info.pinned === true,
                enabled: floating,
                run: () => store.togglePin()
            },
            {
                id: "center",
                label: "Centrar",
                keys: k.center,
                enabled: floating,
                run: () => store.center()
            },
            {
                id: "maximize",
                label: "Maximizar",
                keys: k.maximize,
                checked: info.fullscreen === 1,
                run: () => store.toggleMaximize()
            },
            {
                id: "fullscreen",
                label: "Pantalla completa",
                keys: k.fullscreen,
                checked: info.fullscreen === 2,
                run: () => store.toggleFullscreen()
            },
            {
                id: "group",
                label: "Agrupar",
                keys: k.group,
                checked: (info.grouped?.length ?? 0) > 0,
                run: () => store.toggleGroup()
            },
            {
                id: "capture",
                label: "Capturar",
                keys: k.capture,
                run: () => store.capture()
            }
        ];
        if (store.otherMonitor)
            list.push({
                id: "monitor",
                label: "Mover a " + store.otherMonitor.name,
                run: () => store.moveToMonitor()
            });
        list.push({
            id: "close",
            label: "Cerrar",
            keys: k.close,
            separator: true,
            run: () => store.close()
        });
        list.push({
            id: "kill",
            label: killArmed ? "¿Forzar? Clic otra vez" : "Forzar cierre",
            danger: true,
            armed: killArmed,
            confirm: true,
            run: () => store.kill()
        });
        return list;
    }

    spacing: 6

    signal closeRequested

    // Esc: cancela el «¿Forzar?» antes de cerrar la isla
    function back() {
        if (!killArmed)
            return false;
        killArmed = false;
        return true;
    }

    // Hace la acción y cierra la isla
    function act(fn) {
        fn();
        closeRequested();
    }

    // Ejecuta una fila; «Forzar cierre» pide primero un segundo clic
    function activate(e) {
        if (e.enabled === false)
            return;
        if (e.confirm && !killArmed) {
            killArmed = true;
            killTimer.restart();
            return;
        }
        act(e.run);
    }

    component Section: Text {
        color: App.Theme.grayDark
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
    }

    Section {
        text: "WORKSPACE"
    }
    Row {
        spacing: 6
        Repeater {
            model: App.Config.workspaces.count
            CC.Chip {
                required property int index
                label: String(index + 1)
                selected: !root.inStash && root.info.workspace?.id === index + 1
                onClicked: root.act(() => root.store.moveTo(index + 1))
            }
        }
        CC.Chip {
            label: root.inStash ? "Traer del stash" : "Stash"
            selected: root.inStash
            onClicked: root.act(() => root.store.toggleStash())
        }
    }
    Row {
        spacing: 12
        Row {
            spacing: 6
            KeyCaps {
                anchors.verticalCenter: parent.verticalCenter
                keys: root.cfg.hyprKeys.moveTo
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "mover"
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.xs
            }
        }
        Row {
            spacing: 6
            KeyCaps {
                anchors.verticalCenter: parent.verticalCenter
                keys: root.cfg.hyprKeys.stash
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "stash"
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.xs
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: App.Theme.islandEdge
    }

    Repeater {
        model: root.entries
        Column {
            id: item
            required property var modelData
            width: root.width
            spacing: 6

            Rectangle {
                visible: item.modelData.separator === true
                width: parent.width
                height: 1
                color: App.Theme.islandEdge
            }
            MenuRow {
                label: item.modelData.label
                mnemonic: item.modelData.enabled === false ? -1 : WM.indexOfLetter(item.modelData.label, root.cfg.windowMnemonics[item.modelData.id])
                keys: item.modelData.keys ?? ""
                checked: item.modelData.checked === true
                danger: item.modelData.danger === true
                armed: item.modelData.armed === true
                enabled: item.modelData.enabled !== false
                onClicked: root.activate(item.modelData)
            }
        }
    }

    Timer {
        id: killTimer
        interval: App.Config.activeWindow.killConfirmMs
        onTriggered: root.killArmed = false
    }
}
