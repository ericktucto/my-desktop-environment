import QtQuick
import "../tasks/" as TK
import "../../../../services/timer/" as TM
import "../../../../services/timer/Duration.js" as Duration
import "../../../../" as App

// Un temporizador: nombre, tiempo que falta, barra de progreso y sus botones.
// Sonando (ringing): el rojo late y los botones son +1 min, +5 min y Detener.
Rectangle {
    id: root

    required property var timer
    property bool selected: false

    readonly property var store: TM.TimerStore
    readonly property bool ringing: timer.state === "ringing"
    readonly property bool paused: timer.state === "paused"
    readonly property real leftMs: store.left(timer)
    readonly property real progress: timer.total > 0 ? Math.max(0, Math.min(1, leftMs / timer.total)) : 0

    height: 60
    radius: App.Config.radius.sm
    color: ringing ? Qt.rgba(App.Theme.red.r, App.Theme.red.g, App.Theme.red.b, 0.18) : App.Theme.surface
    border.width: selected || ringing ? 1 : 0
    border.color: ringing ? App.Theme.red : App.Theme.primary

    SequentialAnimation on opacity {
        running: root.ringing
        loops: Animation.Infinite
        onRunningChanged: if (!running)
            root.opacity = 1
        NumberAnimation {
            to: 0.6
            duration: 450
        }
        NumberAnimation {
            to: 1
            duration: 450
        }
    }

    // Nombre y duración total
    Column {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        width: 200

        Text {
            width: parent.width
            text: root.timer.name !== "" ? root.timer.name : "Temporizador"
            color: App.Theme.white
            elide: Text.ElideRight
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.DemiBold
        }
        Text {
            text: Duration.label(root.timer.total) + (root.paused ? " · en pausa" : "")
            color: App.Theme.gray
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.xs
        }
    }

    // Lo que falta (se redondea hacia arriba: 0:01 hasta que llega a cero)
    Text {
        id: time
        anchors.left: parent.left
        anchors.leftMargin: 230
        anchors.verticalCenter: parent.verticalCenter
        width: 90
        text: root.ringing ? "¡Listo!" : Duration.format(Math.ceil(root.leftMs / 1000) * 1000)
        color: root.ringing ? App.Theme.red : (root.paused ? App.Theme.gray : App.Theme.white)
        font.family: App.Config.fonts.mono
        font.pixelSize: App.Config.fontSize.iconLg + 4
        font.weight: Font.Medium
    }

    // Progreso
    Rectangle {
        anchors.left: time.right
        anchors.leftMargin: 8
        anchors.right: buttons.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        radius: 2
        color: App.Theme.track
        visible: !root.ringing

        Rectangle {
            width: parent.width * root.progress
            height: parent.height
            radius: 2
            color: root.paused ? App.Theme.gray : App.Theme.primary
        }
    }

    Row {
        id: buttons
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // Pausar o reanudar
        TK.TaskIconButton {
            visible: !root.ringing
            glyph: root.paused ? 0xf04b : 0xf04c
            onClicked: root.store.toggle(root.timer.id)
        }
        Pill {
            text: "+1"
            visible: !root.ringing
            onClicked: root.store.extend(root.timer.id, 60000)
        }
        TK.TaskIconButton {
            visible: !root.ringing
            glyph: 0xf00d
            onClicked: root.store.remove(root.timer.id)
        }

        // Sonando
        Pill {
            text: "+1 min"
            visible: root.ringing
            onClicked: root.store.extend(root.timer.id, 60000)
        }
        Pill {
            text: "+5 min"
            visible: root.ringing
            onClicked: root.store.extend(root.timer.id, 300000)
        }
        Pill {
            text: "Detener"
            accent: true
            visible: root.ringing
            onClicked: root.store.stopAlarm(root.timer.id)
        }
    }

    component Pill: Rectangle {
        id: pill
        property string text
        property bool accent: false
        signal clicked

        height: 28
        width: label.implicitWidth + 20
        radius: 14
        color: accent ? App.Theme.red : (pm.containsMouse ? App.Theme.surfaceActive : App.Theme.surfaceHover)

        Text {
            id: label
            anchors.centerIn: parent
            text: pill.text
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.sm
            font.weight: Font.DemiBold
        }
        MouseArea {
            id: pm
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }
}
