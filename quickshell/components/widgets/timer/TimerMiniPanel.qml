import QtQuick
import "../media/" as MW
import "../controlcenter/" as CC
import "../../../services/timer/" as TM
import "../../../services/timer/Duration.js" as Duration
import "../../../" as App

// Panel de la pill del temporizador y el cronómetro (isla expandida). Se arma con las mismas piezas que el
// reproductor: fondo (MediaBackdrop), fichas (ItemChips), título, progreso (MediaProgress), botones
// (MediaButton) y, a la derecha, un anillo grande (ProgressRing) en lugar de la carátula.
// Teclado: Espacio pausa o inicia · + suma 1 min · l marca una vuelta · Izquierda y Derecha cambian de ficha · x borra.
Item {
    id: root

    readonly property var cfg: App.Config.media
    readonly property var store: TM.TimerStore
    readonly property var t: store.shown
    readonly property bool sw: store.showsStopwatch

    // Radio de la isla: el fondo se recorta con esas esquinas
    property real islandRadius: App.Config.pill.radiusExpanded

    signal closeRequested

    readonly property bool ringing: t !== null && t.state === "ringing"
    readonly property bool paused: sw ? store.stopwatch.state === "paused" : (t !== null && t.state === "paused")
    readonly property bool running: sw ? store.swRunning : (t !== null && t.state === "running")
    readonly property bool pomo: t !== null && t.pomo !== null

    // Lo que falta (temporizador) o lo transcurrido (cronómetro), en ms
    readonly property real leftMs: t ? store.left(t) : 0
    readonly property real elapsedMs: sw ? store.swElapsed() : (t ? t.total - leftMs : 0)
    readonly property color accent: ringing ? App.Theme.red : (paused ? App.Theme.grayDark : App.Theme.primary)

    // Una ficha por temporizador y el cronómetro
    readonly property var chips: {
        const items = store.timers.map(x => ({
                    key: x.id,
                    label: x.pomo ? "🍅 " + (x.name !== "" ? x.name : "Pomodoro") : store.labelFor(x)
                }));
        if (store.swActive)
            items.push({
                key: "sw",
                label: "Cronómetro"
            });
        return items;
    }

    readonly property string title: sw ? "Cronómetro" : (!t ? "" : (pomo ? "🍅 " + store.phaseLabel(t.pomo) : (t.name !== "" ? t.name : "Temporizador")))
    readonly property string subtitle: {
        if (sw) {
            const rows = store.lapRows;
            return rows.length > 0 ? "Vuelta " + rows[0].n + " · " + Duration.format(rows[0].split, true) : (paused ? "En pausa" : "Corriendo");
        }
        if (!t)
            return "";
        if (ringing)
            return "¡Listo! " + Duration.label(t.total);
        return (pomo && t.name !== "" ? t.name + " · " : "") + Duration.label(t.total) + (paused ? " · en pausa" : "");
    }

    function togglePlaying() {
        if (sw)
            store.swToggle();
        else if (t)
            store.toggle(t.id);
    }

    function shiftChip(d) {
        const i = chips.findIndex(c => c.key === store.viewKey);
        if (chips.length > 1 && i >= 0)
            store.show(chips[(i + d + chips.length) % chips.length].key);
    }

    // El teclado funciona con el panel abierto
    focus: true
    onVisibleChanged: if (visible)
        forceActiveFocus()

    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_Space:
            togglePlaying();
            break;
        case Qt.Key_Plus:
        case Qt.Key_Equal:
            if (t)
                store.extend(t.id, 60000);
            break;
        case Qt.Key_L:
            if (sw)
                store.swLap();
            break;
        case Qt.Key_X:
            if (sw)
                store.swReset();
            else if (t)
                store.remove(t.id);
            break;
        case Qt.Key_Left:
            shiftChip(-1);
            break;
        case Qt.Key_Right:
            shiftChip(1);
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    // ── Fondo: el degradado del color, a todo el ancho de la isla ──
    MW.MediaBackdrop {
        anchors.fill: parent
        anchors.margins: -root.cfg.padding
        accent: root.accent
        tint: 0.18
        islandRadius: root.islandRadius
    }

    // ── Anillo grande con el tiempo (a la derecha) ──
    Item {
        id: ring
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.cfg.artSize
        height: width

        MW.ProgressRing {
            anchors.fill: parent
            ringWidth: 8
            // Temporizador: lo que falta. Cronómetro: el segundero (una vuelta por minuto)
            value: root.sw ? (root.elapsedMs % 60000) / 60000 : (root.t && root.t.total > 0 ? root.leftMs / root.t.total : 0)
            color: root.accent
        }
        Text {
            anchors.centerIn: parent
            text: root.ringing ? "¡Listo!" : (root.sw ? Duration.format(root.elapsedMs) : Duration.format(Math.ceil(root.leftMs / 1000) * 1000))
            color: root.paused ? App.Theme.gray : App.Theme.white
            font.family: App.Config.fonts.mono
            font.pixelSize: 28
            font.weight: Font.Medium
        }
    }

    // ── Columna izquierda ──
    Column {
        id: left
        anchors.left: parent.left
        anchors.right: ring.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        MW.ItemChips {
            visible: root.chips.length > 1
            model: root.chips
            currentKey: root.store.viewKey
            onPicked: key => root.store.show(key)
        }

        Column {
            width: parent.width
            spacing: 2

            Text {
                width: parent.width
                text: root.title
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: 18
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }
            Text {
                width: parent.width
                text: root.subtitle
                visible: text !== ""
                color: root.ringing ? App.Theme.red : App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.lg
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        // Temporizador: lo transcurrido y lo que falta. Cronómetro: sin barra (el anillo es el segundero)
        MW.MediaProgress {
            width: parent.width
            visible: !root.sw
            position: root.elapsedMs / 1000
            length: root.t ? root.t.total / 1000 : 0
            progress: root.t && root.t.total > 0 ? root.elapsedMs / root.t.total : 0
            canSeek: false
            accent: root.accent
        }
        Item {
            width: parent.width
            height: 34
            visible: root.sw
        }

        // Botones: pausa o inicio (el principal) y los de cada tipo
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            // Temporizador: pausar o reanudar
            MW.MediaButton {
                visible: !root.ringing
                icon: root.running ? "media-pause" : "media-play"
                highlighted: true
                accent: root.accent
                onClicked: root.togglePlaying()
            }
            // Sonando: detener
            MW.MediaButton {
                visible: root.ringing
                width: 92
                height: root.cfg.buttonSize
                text: "Detener"
                highlighted: true
                accent: App.Theme.red
                onClicked: root.t && root.store.stopAlarm(root.t.id)
            }
            MW.MediaButton {
                visible: !root.sw
                text: "+1"
                onClicked: root.t && root.store.extend(root.t.id, 60000)
            }
            MW.MediaButton {
                visible: !root.sw
                text: "+5"
                onClicked: root.t && root.store.extend(root.t.id, 300000)
            }
            MW.MediaButton {
                visible: root.pomo && !root.ringing
                icon: "media-next"
                onClicked: root.store.skipPhase()
            }
            MW.MediaButton {
                visible: !root.sw && !root.ringing
                icon: "close"
                iconSize: 16
                onClicked: root.t && root.store.remove(root.t.id)
            }
            // Cronómetro: vuelta y reiniciar
            MW.MediaButton {
                visible: root.sw
                glyph: 0xf024
                onClicked: root.store.swLap()
            }
            MW.MediaButton {
                visible: root.sw
                icon: "restart"
                iconSize: 18
                onClicked: root.store.swReset()
            }
        }

        // Abrir las pestañas completas
        Row {
            height: 28
            CC.Chip {
                anchors.verticalCenter: parent.verticalCenter
                height: 26
                radius: 13
                label: "Abrir en Productividad"
                onClicked: {
                    root.store.openRequested(root.sw ? "stopwatch" : "timer");
                    root.closeRequested();
                }
            }
        }
    }
}
