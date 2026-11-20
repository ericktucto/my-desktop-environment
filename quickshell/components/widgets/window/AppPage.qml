import QtQuick
import "../../../services/windows/" as WS
import "../../../" as App

// Pestaña «App»: acciones de la app, sus ventanas, atajos de edición e información.
Column {
    id: root

    readonly property var store: WS.ActiveWindowStore

    spacing: 10

    signal closeRequested

    function back() {
        return false;
    }

    Text {
        text: root.store.name
        color: App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
    }
}
