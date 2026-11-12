import QtQuick
import Quickshell
import Quickshell.Io
import "../../widgets/applist" as A
import "../../widgets/wallpapers" as W
import "../../widgets/session" as SE
import "../../widgets/controlcenter" as CC
import "../../widgets/clipboard" as CB
import "../../widgets/recorder" as RC
import "../../../services/recorder" as RS
import "../../../services/bluetooth" as BTS
import "../../../services/session" as SS

Rectangle {
    anchors.fill: parent
    color: "transparent"

    property var root
    readonly property real controlHeight: control.implicitHeight
    readonly property real recorderHeight: recorderMenu.implicitHeight

    // Esc: en el centro de control vuelve atrás (renombrado → casillas) antes de cerrar la isla
    function escapeBack() {
        return root.current === 'control' && control.back();
    }

    // Abrir el centro de control (clic derecho en el reloj o IPC): vuelve a leer lo que no avisa
    function refreshControl() {
        control.refresh();
    }

    A.AppList {
        visible: root.current === 'applist'
        anchors.fill: parent
        apps: DesktopEntries.applications.values.filter(a => !a.noDisplay && !a.hidden)
        onCloseRequested: root.close()
        IpcHandler {
            target: "stixshell@launcher"
            function toggle(mon: string): void {
                if (root.expanded && root.current === 'applist') {
                    root.close();
                    return;
                }
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
    CC.ControlCenter {
        id: control
        visible: root.current === 'control'
        width: parent.width
        onSessionRequested: {
            reset();
            root.current = 'session';
        }
        onCloseRequested: root.close()
        // Al cerrar la isla, el centro de control vuelve a las casillas y Bluetooth deja de buscar
        Connections {
            target: root
            function onClosed() {
                control.reset();
            }
        }
        // Una pregunta de emparejamiento (o el ícono de la barra) abre la vista de Bluetooth
        Connections {
            target: BTS.BluetoothStore
            function onOpenPanel() {
                root.current = 'control';
                control.refresh();
                control.openBluetooth();
                root.open();
            }
        }
        IpcHandler {
            target: "stixshell@controlcenter"
            function toggle(mon: string): void {
                if (root.expanded && root.current === 'control') {
                    root.close();
                    return;
                }
                root.current = 'control';
                control.refresh();
                root.open();
            }
        }
    }
    RC.RecorderMenu {
        id: recorderMenu
        visible: root.current === 'recorder'
        width: parent.width
        // El menú lo abre Super+G (IPC) o, tras elegir la carpeta, el propio grabador
        Connections {
            target: RS.RecorderStore
            function onOpenMenu() {
                root.current = 'recorder';
                root.open();
            }
            function onCloseMenu() {
                if (root.current === 'recorder')
                    root.close();
            }
        }
        // Super+G: abre o cierra el menú; con una grabación en curso (o la cuenta regresiva) la cancela o detiene
        IpcHandler {
            target: "stixshell@recorder"
            function toggle(mon: string): void {
                if (RS.RecorderStore.active || RS.RecorderStore.picking) {
                    RS.RecorderStore.stopOrCancel();
                    return;
                }
                if (root.expanded && root.current === 'recorder') {
                    root.close();
                    return;
                }
                root.current = 'recorder';
                root.open();
            }
            function stop(): void {
                RS.RecorderStore.stopOrCancel();
            }
        }
    }
    CB.ClipboardPanel {
        visible: root.current === 'clipboard'
        anchors.fill: parent
        onCloseRequested: root.close()
        IpcHandler {
            target: "stixshell@clipboard"
            function toggle(mon: string): void {
                if (root.expanded && root.current === 'clipboard') {
                    root.close();
                    return;
                }
                root.current = 'clipboard';
                root.open();
            }
        }
    }
}
