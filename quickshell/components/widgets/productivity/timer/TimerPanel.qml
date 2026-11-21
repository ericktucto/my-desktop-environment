import QtQuick
import "../../../controls/" as C
import "../../controlcenter/" as CC
import "../tasks/" as TK
import "../../../../services/tasks/" as TS
import "../../../../services/timer/" as TM
import "../../../../services/timer/Duration.js" as Duration
import "../../../../services/settings/" as ST
import "../../../../" as App

// Pestaña Temporizador: un campo para escribir el tiempo ("10m té", "1h30", "5:00"), los tiempos rápidos y
// recientes, la lista de temporizadores y el sonido de la alarma.
// Teclado: Ctrl+P empieza un Pomodoro · Enter crea · Abajo pasa a la lista (j/k elegir, Espacio pausar, x borrar, / vuelve al campo).
FocusScope {
    id: root

    signal closeRequested

    readonly property var store: TM.TimerStore
    readonly property var cfg: App.Config.timer
    property int sel: -1
    // Elegir la tarea de un Pomodoro
    property bool picking: false
    property int pickSel: 0

    // Lo que dice el campo, ya entendido (o null)
    readonly property var parsed: Duration.parse(field.text)

    function focusInput() {
        field.giveFocus();
    }

    // Esc: borra lo escrito; si no hay nada, deja que se cierre la isla
    function back() {
        if (picking) {
            closePicker();
            return true;
        }
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
        closePicker();
    }

    // ── Pomodoro: elegir la tarea ──
    function openPicker() {
        if (store.pomodoro)
            return;
        pickField.text = "";
        pickSel = 0;
        picking = true;
        pickField.giveFocus();
    }

    function closePicker() {
        if (!picking)
            return;
        picking = false;
        field.giveFocus();
    }

    // Sin tarea y luego Hoy y en curso (o lo que se busque), sin lo ya cerrado
    readonly property var picks: {
        if (!picking)
            return [];
        const q = pickField.text.trim();
        let found = [];
        if (q === "")
            TS.TaskStore.list("today", "").forEach(g => found = found.concat(g.tasks));
        else
            found = TS.TaskStore.search(q);
        return [
            {
                id: "",
                title: "Sin tarea",
                where: ""
            }
        ].concat(found.filter(t => t.status !== "done" && t.status !== "cancelled").slice(0, 30).map(t => ({
                    id: t.id,
                    title: t.title,
                    where: TS.TaskStore.whereIs(t)
                })));
    }

    function pick(i) {
        const p = picks[i];
        if (!p)
            return;
        store.startPomodoro(p.id);
        closePicker();
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
        // Ctrl+P: empezar un Pomodoro (elegir la tarea)
        if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) {
            if (picking)
                closePicker();
            else
                openPicker();
            event.accepted = true;
            return;
        }
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
            model: ST.SettingsStore.timer.presets
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

    // ── Pomodoro ──
    Row {
        id: pomoRow
        anchors.top: recents.visible ? recents.bottom : quick.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        spacing: 6

        CC.Chip {
            label: root.store.pomodoro ? "🍅 " + root.store.phaseLabel(root.store.pomodoro.pomo) : "🍅 Pomodoro"
            selected: root.store.pomodoro !== null || root.picking
            onClicked: root.picking ? root.closePicker() : root.openPicker()
        }
        CC.Chip {
            visible: root.store.pomodoro !== null
            label: "Saltar tramo"
            onClicked: root.store.skipPhase()
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.store.pomodoro === null && !root.picking
            text: App.Config.timer.pomodoro.work + " min de trabajo · " + App.Config.timer.pomodoro.short + " de descanso"
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.xs
        }
    }

    // ── Lista ──
    ListView {
        id: list
        anchors.top: pomoRow.bottom
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

    // ── Elegir la tarea del Pomodoro ──
    Rectangle {
        id: picker
        anchors.top: pomoRow.bottom
        anchors.topMargin: 8
        anchors.bottom: sound.top
        anchors.bottomMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.picking
        radius: App.Config.radius.sm
        color: App.Theme.island
        border.width: 1
        border.color: App.Theme.surfaceHigh

        C.TextField {
            id: pickField
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            width: undefined
            height: 36
            placeholder: "Buscar una tarea para el Pomodoro…"
            onTextChanged: root.pickSel = 0
            onPressedKey: key => {
                if (key === Qt.Key_Enter)
                    root.pick(root.pickSel);
                else if (key === Qt.Key_Down)
                    root.pickSel = Math.min(root.picks.length - 1, root.pickSel + 1);
                else if (key === Qt.Key_Up)
                    root.pickSel = Math.max(0, root.pickSel - 1);
            }
        }

        ListView {
            anchors.top: pickField.bottom
            anchors.topMargin: 6
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            clip: true
            spacing: 2
            model: root.picks
            currentIndex: root.pickSel
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
                required property int index
                required property var modelData
                width: ListView.view.width
                height: 34
                radius: 6
                color: root.pickSel === index || pm.containsMouse ? App.Theme.surfaceActive : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: whereText.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.title
                    elide: Text.ElideRight
                    color: modelData.id === "" ? App.Theme.gray : App.Theme.white
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.md
                }
                Text {
                    id: whereText
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.where
                    color: App.Theme.gray
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                }
                MouseArea {
                    id: pm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pick(index)
                }
            }
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
