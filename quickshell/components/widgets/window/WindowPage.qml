import QtQuick
import "../controlcenter/" as CC
import "../../../services/windows/" as WS
import "../../../" as App

// Pestaña «Ventana»: acciones sobre la ventana (workspaces, estado, cerrar).
Column {
    id: root

    readonly property var store: WS.ActiveWindowStore

    spacing: 10

    signal closeRequested

    function back() {
        return false;
    }

    Row {
        spacing: 8
        CC.SmallButton {
            label: "Cerrar"
            onClicked: {
                root.store.close();
                root.closeRequested();
            }
        }
    }
}
