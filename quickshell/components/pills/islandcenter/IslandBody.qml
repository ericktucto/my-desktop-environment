import QtQuick
import Quickshell
import Quickshell.Io
import "../../widgets/applist" as A
import "../../widgets/wallpapers" as W
import "../../widgets/session" as SE
import "../../../services/session" as SS

Rectangle {
    anchors.fill: parent
    color: "transparent"

    property var root

    A.AppList {
        visible: root.current === 'applist'
        anchors.fill: parent
        apps: DesktopEntries.applications.values.filter(a => !a.noDisplay && !a.hidden)
        onAppLaunched: function (app) {
            root.expanded = false;
            if (app)
                app.execute();
        }
        IpcHandler {
            target: "stixshell@launcher"
            function toggle(mon: string): void {
                root.current = 'applist';
                root.open();
            }
        }
    }
    W.Wallpapers {
        id: wallpapers
        visible: root.current === 'wallpapers'
        onClosed: root.close()
        IpcHandler {
            target: "stixshell@wallpaper"
            function toggle(mon: string): void {
                root.current = 'wallpapers';
                wallpapers.scanWallpapers();
                wallpapers.giveFocus();
                root.open();
            }
        }
    }
    SE.SessionMenu {
        visible: root.current === 'session'
        anchors.fill: parent
        onChosen: function (id) {
            root.close();
            SS.SessionStore.run(id);
        }
        IpcHandler {
            target: "stixshell@session"
            function toggle(mon: string): void {
                if (root.expanded && root.current === 'session') {
                    root.close();
                    return;
                }
                root.current = 'session';
                root.open();
            }
        }
    }
}
