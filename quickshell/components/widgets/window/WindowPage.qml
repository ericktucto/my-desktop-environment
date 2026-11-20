import QtQuick
import "../controlcenter/" as CC
import "../../../services/windows/" as WS
import "../../../" as App

// Pestaña «Ventana»: mover a un workspace o al stash, estado (flotante, fijada, maximizada…), capturar,
// mover al otro monitor, cerrar y forzar el cierre. Cada acción cierra la isla.
Column {
    id: root

    readonly property var store: WS.ActiveWindowStore
    readonly property var info: store.info
    readonly property bool floating: info.floating === true
    readonly property bool inStash: (info.workspace?.name ?? "") === "special:stash"
    // «Forzar cierre» espera un segundo clic
    property bool killArmed: false

    spacing: 8

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

    Section {
        text: "VENTANA"
    }
    Flow {
        width: parent.width
        spacing: 6
        CC.Chip {
            label: "Flotante"
            selected: root.floating
            onClicked: root.act(() => root.store.toggleFloat())
        }
        CC.Chip {
            label: "Fijar"
            selected: root.info.pinned === true
            enabled: root.floating
            opacity: enabled ? 1 : 0.4
            onClicked: root.act(() => root.store.togglePin())
        }
        CC.Chip {
            label: "Centrar"
            enabled: root.floating
            opacity: enabled ? 1 : 0.4
            onClicked: root.act(() => root.store.center())
        }
        CC.Chip {
            label: "Maximizar"
            selected: root.info.fullscreen === 1
            onClicked: root.act(() => root.store.toggleMaximize())
        }
        CC.Chip {
            label: "Pantalla completa"
            selected: root.info.fullscreen === 2
            onClicked: root.act(() => root.store.toggleFullscreen())
        }
        CC.Chip {
            label: "Agrupar"
            selected: (root.info.grouped?.length ?? 0) > 0
            onClicked: root.act(() => root.store.toggleGroup())
        }
        CC.Chip {
            label: "Capturar"
            onClicked: root.act(() => root.store.capture())
        }
        CC.Chip {
            visible: root.store.otherMonitor !== null
            label: "Mover a " + (root.store.otherMonitor?.name ?? "")
            onClicked: root.act(() => root.store.moveToMonitor())
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: App.Theme.islandEdge
    }

    Item {
        width: parent.width
        height: 32

        CC.SmallButton {
            label: "Cerrar"
            onClicked: root.act(() => root.store.close())
        }

        // Mata el proceso: pide un segundo clic
        Rectangle {
            anchors.right: parent.right
            width: killText.implicitWidth + 32
            height: 32
            radius: 16
            color: root.killArmed ? App.Theme.red : (killMouse.containsMouse ? App.Theme.surfaceActive : App.Theme.surface)
            Text {
                id: killText
                anchors.centerIn: parent
                text: root.killArmed ? "¿Forzar? Clic otra vez" : "Forzar cierre"
                color: root.killArmed ? App.Theme.white : App.Theme.red
                font.family: App.Config.fonts.text
                font.pixelSize: App.Config.fontSize.sm
                font.weight: Font.DemiBold
            }
            MouseArea {
                id: killMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.killArmed) {
                        root.act(() => root.store.kill());
                    } else {
                        root.killArmed = true;
                        killTimer.restart();
                    }
                }
            }
        }
    }

    Timer {
        id: killTimer
        interval: App.Config.activeWindow.killConfirmMs
        onTriggered: root.killArmed = false
    }
}
