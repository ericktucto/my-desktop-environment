import QtQuick
import "../../../controls/" as C
import "../../controlcenter/" as CC
import "../tasks/" as TK
import "../../../../services/timer/" as TM
import "../../../../services/timer/Duration.js" as Duration
import "../../../../services/settings/" as ST
import "../../../../" as App

// Pestaña Temporizador: un campo para escribir el tiempo ("10m té", "1h30", "5:00"), los tiempos rápidos y
// recientes, la lista de temporizadores y el sonido de la alarma.
// Teclado: Enter crea · Abajo o Tab pasa a la lista (j/k elegir, Espacio pausar, x borrar, / vuelve al campo).
FocusScope {
    id: root

    signal closeRequested

    readonly property var store: TM.TimerStore
    readonly property var cfg: App.Config.timer
    property int sel: -1

    // Lo que dice el campo, ya entendido (o null)
    readonly property var parsed: Duration.parse(field.text)

    function focusInput() {
        field.giveFocus();
    }

    // Esc: borra lo escrito; si no hay nada, deja que se cierre la isla
    function back() {
        if (field.text !== "") {
            field.text = "";
            return true;
        }
        if (sel >= 0) {
            sel = -1;
            field.giveFocus();
            return true;
        }
        return false;
    }

    function reset() {
        field.text = "";
        sel = -1;
    }

    function create() {
        const id = store.addFromText(field.text);
        if (id !== "") {
            field.text = "";
            sel = -1;
        }
    }

    function presetLabel(min) {
        return min >= 60 ? (min / 60) + " h" : min + " min";
    }

    function move(d) {
        const n = store.timers.length;
        if (n === 0)
            return;
        sel = Math.max(0, Math.min(n - 1, (sel < 0 ? (d > 0 ? -1 : n) : sel) + d));
        list.positionViewAtIndex(sel, ListView.Contain);
    }

    Keys.onPressed: event => {
        if (field.typing || event.modifiers & (Qt.ControlModifier | Qt.AltModifier))
            return;
        const t = store.timers[root.sel];
        if (event.key === Qt.Key_J || event.key === Qt.Key_Down)
            move(1);
        else if (event.key === Qt.Key_K || event.key === Qt.Key_Up)
            move(-1);
        else if (event.key === Qt.Key_Space && t)
            store.toggle(t.id);
        else if (event.key === Qt.Key_X && t)
            store.remove(t.id);
        else if (event.key === Qt.Key_Slash || event.key === Qt.Key_I || event.key === Qt.Key_N)
            field.giveFocus();
        else
            return;
        event.accepted = true;
    }

    // Se creó o se quitó uno: la selección no se sale de la lista
    Connections {
        target: root.store
        function onTimersChanged() {
            if (root.sel >= root.store.timers.length)
                root.sel = root.store.timers.length - 1;
        }
    }

    // ── Nuevo ──
    Row {
        id: top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        C.TextField {
            id: field
            width: parent.width - 44
            height: 38
            placeholder: "Nuevo: 10m té, 1h30, 5:00, 45s…"
            onPressedKey: key => {
                if (key === Qt.Key_Enter)
                    root.create();
                else if (key === Qt.Key_Down && root.store.timers.length > 0) {
                    root.forceActiveFocus();
                    root.move(1);
                }
            }
        }
        TK.TaskIconButton {
            anchors.verticalCenter: parent.verticalCenter
            size: 36
            glyph: 0xf04b
            active: root.parsed !== null
            opacity: root.parsed !== null ? 1 : 0.5
            onClicked: root.create()
        }
    }

    // Lo que entendió
    Text {
        id: hint
        anchors.top: top.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.leftMargin: 4
        height: 16
        text: field.text === "" ? "" : (root.parsed ? "Temporizador de " + Duration.label(root.parsed.ms) + (root.parsed.name !== "" ? " · " + root.parsed.name : "") : "No entiendo ese tiempo")
        color: root.parsed || field.text === "" ? App.Theme.gray : App.Theme.amber
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.xs
    }

    // ── Tiempos rápidos y recientes ──
    Flow {
        id: quick
        anchors.top: hint.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 6

        Repeater {
            model: root.cfg.presets
            CC.Chip {
                required property int modelData
                label: root.presetLabel(modelData)
                onClicked: root.store.add(modelData * 60000, "")
            }
        }
    }

    Flow {
        id: recents
        anchors.top: quick.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 6
        visible: root.store.recents.length > 0

        Text {
            height: 30
            verticalAlignment: Text.AlignVCenter
            text: "Recientes"
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
        }
        Repeater {
            model: root.store.recents
            CC.Chip {
                required property var modelData
                label: (modelData.name !== "" ? modelData.name + " " : "") + Duration.label(modelData.ms).replace(" min", "m").replace(" h ", "h ").replace(/ h$/, "h").replace(" s", "s")
                onClicked: root.store.add(modelData.ms, modelData.name)
            }
        }
    }

    // ── Lista ──
    ListView {
        id: list
        anchors.top: recents.visible ? recents.bottom : quick.bottom
        anchors.topMargin: 12
        anchors.bottom: sound.top
        anchors.bottomMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true
        spacing: 6
        model: root.store.timers

        delegate: TimerCard {
            required property int index
            required property var modelData
            width: list.width
            timer: modelData
            selected: root.sel === index
        }

        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            horizontalAlignment: Text.AlignHCenter
            text: "Sin temporizadores\nEscribe un tiempo o elige uno rápido"
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            lineHeight: 1.3
        }
    }

    // ── Sonido ──
    Item {
        id: sound
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 30

        readonly property bool custom: ST.SettingsStore.timer.sound !== "system" && ST.SettingsStore.timer.sound !== ""

        Row {
            spacing: 6
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.verticalCenter: parent.verticalCenter
                rightPadding: 4
                text: "Sonido"
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
            }
            CC.Chip {
                label: "Sistema"
                selected: !sound.custom
                onClicked: root.store.setSound("system")
            }
            CC.Chip {
                label: sound.custom ? ST.SettingsStore.timer.sound.split("/").pop() : "Archivo…"
                selected: sound.custom
                onClicked: root.store.pickSound()
            }
            TK.TaskIconButton {
                anchors.verticalCenter: parent.verticalCenter
                size: 30
                glyph: 0xf04b
                onClicked: root.store.testSound()
            }
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.store.soundOk
            text: sound.custom ? "No se encuentra el archivo" : "Falta sound-theme-freedesktop"
            color: App.Theme.amber
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.xs
        }
    }
}
