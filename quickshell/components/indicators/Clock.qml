import QtQuick
import Quickshell
import Quickshell.Io
import "../base" as Base
import "../../" as App
import "./../../components/widgets/applist" as A
import "./../../components/widgets/wallpapers" as W

Base.Island {
    id: root

    property string current: 'applist'

    expandedHeight: {
        if (current == 'applist')
            return 600;
        if (current == 'wallpapers')
            return App.Config.imgHeight * 2 + App.Config.spacingCell * 2 + 32;
        return 300;
    }
    expandedWidth: {
        if (current == 'applist')
            return 480;
        if (current == 'wallpapers')
            return 800;
        return 400;
    }

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

    // El SystemClock vive AQUÍ, dentro del componente Clock
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    body: Rectangle {
        anchors.fill: parent
        color: "transparent"

        A.AppList {
            visible: current == 'applist'
            anchors.fill: parent
            anchors.margins: 8
            apps: DesktopEntries.applications.values.filter(a => !a.noDisplay && !a.hidden)
            onAppLaunched: function (app) {
                root.expanded = false;

                // Opción A: nativo (recomendado)
                if (app && app.execute) {
                    app.execute();
                    return;
                }

                // Opción B: fallback manual si execute no funciona en tu versión
                const execCmd = (app && app.execString) ? app.execString : "";
                if (!execCmd)
                    return;
                const proc = Qt.createQmlObject(`
                    import Quickshell.Io;
                    Process {
                        command: ["sh", "-c", ${JSON.stringify(execCmd)}]
                        running: true
                    }
                `, root);
            }
            IpcHandler {
                target: "stixshell@launcher"
                function toggle(mon: string): void {
                    current = 'applist';
                    root.open();
                }
            }
        }
        W.Wallpapers {
            id: wallpapers
            visible: current == 'wallpapers'
            onClosed: root.close()
            IpcHandler {
                target: "stixshell@wallpaper"
                function toggle(mon: string): void {
                    current = 'wallpapers';
                    wallpapers.scanWallpapers();
                    wallpapers.giveFocus();
                    root.open();
                }
            }
        }
    }

    onOpened: {
        console.log("Island abierta, wallpaper actual", App.Wallpaper.current);
    }
}
