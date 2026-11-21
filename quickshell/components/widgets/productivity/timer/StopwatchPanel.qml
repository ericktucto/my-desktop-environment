import QtQuick
import "../../../../services/timer/" as TM
import "../../../../services/timer/Duration.js" as Duration
import "../../../../" as App

// Pestaña Cronómetro: tiempo grande con centésimas, Iniciar/Pausar, Vuelta y Reiniciar, y la lista de vueltas
// (la más rápida en verde y la más lenta en rojo). Teclado: Espacio inicia o pausa, l marca una vuelta, r reinicia.
FocusScope {
    id: root

    signal closeRequested

    readonly property var store: TM.TimerStore
    readonly property bool running: store.swRunning
    readonly property string state: store.stopwatch.state

    // Con la pestaña a la vista, el tiempo se actualiza más seguido (centésimas)
    Binding {
        target: root.store
        property: "watching"
        value: root.visible
        when: root.visible
        restoreMode: Binding.RestoreValue
    }

    function back() {
        return false;
    }

    function reset() {
    }

    Keys.onPressed: event => {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier))
            return;
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            store.swToggle();
        else if (event.key === Qt.Key_L)
            store.swLap();
        else if (event.key === Qt.Key_R)
            store.swReset();
        else
            return;
        event.accepted = true;
    }

    Text {
        id: big
        anchors.top: parent.top
        anchors.topMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        text: Duration.format(root.store.swElapsed(), true)
        color: root.state === "paused" ? App.Theme.gray : App.Theme.white
        font.family: App.Config.fonts.mono
        font.pixelSize: 64
        font.weight: Font.Medium

        // Se vuelve a leer con cada tick del reloj de la tienda
        Connections {
            target: root.store
            function onNowChanged() {
                big.text = Duration.format(root.store.swElapsed(), true);
            }
            function onStopwatchChanged() {
                big.text = Duration.format(root.store.swElapsed(), true);
            }
        }
    }

    Row {
        id: buttons
        anchors.top: big.bottom
        anchors.topMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        Btn {
            text: root.running ? "Pausar" : (root.state === "paused" ? "Seguir" : "Iniciar")
            primary: true
            onClicked: root.store.swToggle()
        }
        Btn {
            text: "Vuelta"
            enabled: root.state !== "idle"
            onClicked: root.store.swLap()
        }
        Btn {
            text: "Reiniciar"
            enabled: root.state !== "idle"
            onClicked: root.store.swReset()
        }
    }

    // ── Vueltas ──
    Rectangle {
        id: head
        anchors.top: buttons.bottom
        anchors.topMargin: 22
        anchors.left: parent.left
        anchors.right: parent.right
        height: 24
        color: "transparent"
        visible: root.store.lapRows.length > 0

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 14
            Repeater {
                model: [
                    {
                        t: "Vuelta",
                        w: 90
                    },
                    {
                        t: "Tiempo",
                        w: 160
                    },
                    {
                        t: "Total",
                        w: 160
                    }
                ]
                Text {
                    required property var modelData
                    width: modelData.w
                    text: modelData.t
                    color: App.Theme.gray
                    font.family: App.Config.fonts.text
                    font.pixelSize: App.Config.fontSize.xs
                }
            }
        }
        Pill {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "Copiar vueltas"
            onClicked: root.store.copyLaps()
        }
    }

    ListView {
        id: laps
        anchors.top: head.bottom
        anchors.topMargin: 4
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true
        spacing: 4
        model: root.store.lapRows

        delegate: Rectangle {
            required property var modelData
            width: laps.width
            height: 34
            radius: App.Config.radius.sm
            color: App.Theme.surface

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 14
                Repeater {
                    model: [
                        {
                            t: String(modelData.n),
                            w: 90,
                            hl: false
                        },
                        {
                            t: Duration.format(modelData.split, true),
                            w: 160,
                            hl: true
                        },
                        {
                            t: Duration.format(modelData.total, true),
                            w: 160,
                            hl: false
                        }
                    ]
                    Text {
                        required property var modelData
                        width: modelData.w
                        text: modelData.t
                        color: modelData.hl ? (laps.model && parent.parent.modelData.best ? App.Theme.green : (parent.parent.modelData.worst ? App.Theme.red : App.Theme.white)) : App.Theme.white
                        font.family: App.Config.fonts.mono
                        font.pixelSize: App.Config.fontSize.md
                    }
                }
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: laps.verticalCenter
        visible: root.store.lapRows.length === 0
        horizontalAlignment: Text.AlignHCenter
        text: root.state === "idle" ? "Espacio inicia · l marca una vuelta · r reinicia" : "Pulsa Vuelta para marcar una"
        color: App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.md
    }

    component Btn: Rectangle {
        id: btn
        property string text
        property bool primary: false
        signal clicked

        width: 130
        height: 40
        radius: 20
        opacity: enabled ? 1 : 0.4
        color: primary ? App.Theme.primary : (bm.containsMouse && enabled ? App.Theme.surfaceActive : App.Theme.surface)

        Text {
            anchors.centerIn: parent
            text: btn.text
            color: btn.primary ? App.Theme.onPrimary : App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.md
            font.weight: Font.DemiBold
        }
        MouseArea {
            id: bm
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    component Pill: Rectangle {
        id: pill
        property string text
        signal clicked

        height: 24
        width: label.implicitWidth + 20
        radius: 12
        color: pm.containsMouse ? App.Theme.surfaceActive : App.Theme.surface

        Text {
            id: label
            anchors.centerIn: parent
            text: pill.text
            color: App.Theme.white
            font.family: App.Config.fonts.text
            font.pixelSize: App.Config.fontSize.xs
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
