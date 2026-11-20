import QtQuick
import "../controlcenter/" as CC
import "../../../services/windows/" as WS
import "../../../services/windows/WindowMenu.js" as WM
import "../../../services/workspaces/" as W
import "../../../" as App

// Pestaña «App», como lista tipo menú: Abrir (acciones del .desktop, con el atajo que tenga la app),
// Ventanas (las de la misma app, numeradas), «Editar ›» (atajos que se mandan a la ventana: Deshacer,
// Copiar, Pegar…; se ajustan por app en Config.activeWindow) e información de la ventana.
// Hyprland no deja leer el menú «Archivo, Editar…» de la app: esto es lo que sí se puede ofrecer.
Column {
    id: root

    readonly property var store: WS.ActiveWindowStore
    readonly property var info: store.info
    readonly property var cfg: App.Config.activeWindow
    readonly property var windows: store.sameApp
    // «Editar ›» desplegado
    property bool editOpen: false
    property bool copied: false
    // Fila elegida con el teclado (la fija el panel)
    property int cursor: -1

    // Las filas en el orden en que se ven (el teclado recorre las mismas). `header` marca el inicio de una sección.
    readonly property var entries: {
        const out = [];
        const acts = store.desktopActions;
        const actionKeys = cfg.appShortcuts[(store.appId ?? "").toLowerCase()]?.actionKeys ?? ({});
        const labels = [];
        // Letras de las filas que no son ventanas, asignadas en orden (las ventanas usan 1–9)
        acts.forEach(a => labels.push(a.name));
        if (acts.length === 0)
            labels.push("Abrir otra instancia");
        labels.push("Editar");
        if (editOpen)
            store.shortcuts.forEach(s => labels.push(s.label));
        const mn = WM.assignMnemonics(labels, []);
        let n = 0;

        acts.forEach(a => out.push({
                id: "act:" + a.id,
                header: n === 0 ? "ABRIR" : "",
                label: a.name,
                mnemonic: mn[n++],
                keys: actionKeys[a.id] ?? "",
                run: () => a.execute()
            }));
        if (acts.length === 0)
            out.push({
                id: "new",
                header: "ABRIR",
                label: "Abrir otra instancia",
                mnemonic: mn[n++],
                run: () => store.newInstance()
            });

        const wins = windows.slice(0, 9);
        wins.forEach((t, i) => out.push({
                id: "win:" + t.address,
                header: i === 0 ? "VENTANAS" : "",
                label: (i + 1) + "  " + (W.WorkspaceStore.titleOf(t) || store.name),
                mnemonic: 0,
                digit: i + 1,
                trailing: String(t.workspace?.id ?? ""),
                checked: t.address === store.targetAddress,
                run: () => store.focusWindow(t)
            }));

        out.push({
            id: "edit",
            header: "EDITAR",
            label: "Editar",
            mnemonic: mn[n++],
            submenu: editOpen ? "⌄" : "›",
            toggle: true
        });
        if (editOpen)
            store.shortcuts.forEach(s => out.push({
                    id: "key:" + s.keys + s.label,
                    label: s.label,
                    mnemonic: mn[n++],
                    keys: s.keys,
                    indent: true,
                    run: () => store.sendShortcutLater(s.keys)
                }));
        return out;
    }

    spacing: 4

    signal closeRequested

    // Esc: pliega «Editar ›» antes de cerrar la isla
    function back() {
        if (!editOpen)
            return false;
        editOpen = false;
        return true;
    }

    // Ejecuta una fila: «Editar ›» se despliega; las demás hacen la acción y cierran la isla
    function activate(e) {
        if (e.toggle) {
            editOpen = !editOpen;
            return;
        }
        e.run();
        closeRequested();
    }

    // Una tecla del teclado: 1–9 salta a esa ventana y la letra subrayada de cada fila la ejecuta
    function handleKey(text) {
        const e = entries.find(x => x.digit !== undefined ? String(x.digit) === text : (x.mnemonic >= 0 && WM.norm(x.label.charAt(x.mnemonic)) === text));
        if (!e)
            return false;
        activate(e);
        return true;
    }

    component Section: Text {
        topPadding: 4
        color: App.Theme.grayDark
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
    }

    Repeater {
        model: root.entries
        Column {
            id: item
            required property var modelData
            required property int index
            width: root.width
            spacing: 4

            Section {
                visible: (item.modelData.header ?? "") !== ""
                text: item.modelData.header ?? ""
            }
            MenuRow {
                label: item.modelData.label
                mnemonic: item.modelData.mnemonic ?? -1
                keys: item.modelData.keys ?? ""
                trailing: item.modelData.trailing ?? ""
                checked: item.modelData.checked === true
                submenu: item.modelData.submenu ?? ""
                // Las ventanas y los atajos de Editar dejan el hueco del ✓; las acciones se alinean al borde
                showCheck: item.modelData.indent === true || item.modelData.digit !== undefined
                selected: root.cursor === item.index
                onClicked: root.activate(item.modelData)
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: App.Theme.islandEdge
    }

    // Información de la ventana; el clic copia la clase (sirve para escribir reglas de ventana)
    Item {
        width: parent.width
        height: 30

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: copy.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: [root.store.className, root.info.pid ? "PID " + root.info.pid : "", root.info.xwayland ? "Xwayland" : "Wayland", root.info.workspace ? "ws " + root.info.workspace.name : ""].filter(x => x !== "").join(" · ")
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.xs
        }
        CC.Chip {
            id: copy
            anchors.right: parent.right
            height: 26
            radius: 13
            label: root.copied ? "Copiada ✓" : "Copiar clase"
            onClicked: {
                root.store.copyClass();
                root.copied = true;
                copiedTimer.restart();
            }
        }
        Timer {
            id: copiedTimer
            interval: 1500
            onTriggered: root.copied = false
        }
    }
}
