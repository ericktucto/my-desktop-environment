import QtQuick
import Quickshell
import Quickshell.Io
import "./../../../components/widgets/applist" as A
import "./../../../components/widgets/wallpapers" as W

Rectangle {
    anchors.fill: parent
    color: "transparent"

    property string current: 'applist'
    property var root

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
