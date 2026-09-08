import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../base" as Base
import "../../" as App
import "./../../components/widgets/applist" as A

Base.Island {
    id: root

    expandedHeight: 600
    expandedWidth: 480
    radiusExpanded: 32

    preventFocus: true

    Text {
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: App.Theme.white
        font.family: "JetBrains Mono"
        font.pixelSize: 13
        font.weight: Font.Medium
        anchors.verticalCenter: parent.verticalCenter
    }

    body: Rectangle {
        anchors.fill: parent
        color: "transparent"

        A.AppList {
            anchors.fill: parent
            anchors.margins: 8
            apps: DesktopEntries.applications.values.filter(a => !a.noDisplay && !a.hidden)
            onAppLaunched: function (app) {
                root.expanded = false

                // Opción A: nativo (recomendado)
                if (app && app.execute) {
                    app.execute()
                    return
                }

                // Opción B: fallback manual si execute no funciona en tu versión
                const execCmd = (app && app.execString) ? app.execString : ""
                if (!execCmd) return

                const proc = Qt.createQmlObject(`
                    import Quickshell.Io;
                    Process {
                        command: ["sh", "-c", ${JSON.stringify(execCmd)}]
                        running: true
                    }
                `, root)
            }
            IpcHandler {
                target: "stixshell@launcher"
                function toggle(mon: string): void {
                    root.open()
                }
            }
        }
    }

    onOpened: {
        console.log("Island abierta")
    }

    // El SystemClock vive AQUÍ, dentro del componente Clock
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
