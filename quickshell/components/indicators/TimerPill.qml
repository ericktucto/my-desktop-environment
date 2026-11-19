import QtQuick
import "../base" as Base
import "../../services/timer/" as TM
import "../../services/timer/Duration.js" as Duration
import "../../" as App

// Temporizador y cronómetro a la derecha del reloj: "⏳ 4:59 +1  ⏱ 12:30".
// Clic en un lado abre su pestaña; clic derecho lo pausa o reanuda. Sonando, late en rojo y el clic detiene la alarma.
Base.Island {
    id: root

    readonly property var store: TM.TimerStore
    readonly property var next: store.next
    readonly property bool ringing: next !== null && next.state === "ringing"
    // Cuántos más hay además del que se ve
    readonly property int more: Math.max(0, store.timers.filter(t => t.state === "running" || t.state === "ringing").length - 1)

    visible: next !== null || store.swActive
    openOnClick: false

    // ── Temporizador ──
    Item {
        id: timerSeg
        visible: root.next !== null
        implicitWidth: timerRow.implicitWidth
        implicitHeight: timerRow.implicitHeight
        // Aire entre el temporizador y el cronómetro
        width: implicitWidth + (swSeg.visible ? 12 : 0)
        height: App.Config.pill.height

        SequentialAnimation on opacity {
            running: root.ringing && timerSeg.visible
            loops: Animation.Infinite
            onRunningChanged: if (!running)
                timerSeg.opacity = 1
            NumberAnimation {
                to: 0.45
                duration: 450
            }
            NumberAnimation {
                to: 1
                duration: 450
            }
        }

        Row {
            id: timerRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: String.fromCodePoint(root.ringing ? 0xf0f3 : 0xf252)
                color: root.ringing ? App.Theme.red : App.Theme.amber
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.sm
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.ringing ? ((root.next.name !== "" ? root.next.name + " · " : "") + "¡Listo!") : Duration.format(Math.ceil(root.store.left(root.next) / 1000) * 1000)
                color: root.ringing ? App.Theme.red : App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
                font.weight: Font.DemiBold
                font.letterSpacing: -0.5
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.more > 0
                text: "+" + root.more
                color: App.Theme.gray
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.xs
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (!root.next)
                    return;
                if (root.ringing)
                    root.store.ringing.forEach(t => root.store.stopAlarm(t.id));
                else if (mouse.button === Qt.RightButton)
                    root.store.pause(root.next.id);
                else
                    root.store.openRequested("timer");
            }
        }
    }

    // ── Cronómetro ──
    Item {
        id: swSeg
        visible: root.store.swActive
        implicitWidth: swRow.implicitWidth
        implicitHeight: swRow.implicitHeight
        width: implicitWidth
        height: App.Config.pill.height

        Row {
            id: swRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5
            opacity: root.store.swRunning ? 1 : 0.6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: String.fromCodePoint(0xf2f2)
                color: App.Theme.primary
                font.family: App.Config.fonts.icons
                font.pixelSize: App.Config.fontSize.sm
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Duration.format(root.store.swElapsed())
                color: App.Theme.white
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
                font.weight: Font.DemiBold
                font.letterSpacing: -0.5
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.store.swToggle();
                else
                    root.store.openRequested("stopwatch");
            }
        }
    }
}
