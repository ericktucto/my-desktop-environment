import QtQuick
import "../../../../services/tasks/" as TS
import "../../../../" as App

// Pestaña Tareas (el esqueleto del paso 1.4; la barra lateral y la lista llegan en el 1.5).
Item {
    id: root

    signal closeRequested

    focus: true

    // Esc: true si cerró algo dentro de la pestaña
    function back() {
        return false;
    }

    function reset() {
    }

    Text {
        anchors.centerIn: parent
        text: TS.TaskStore.error !== "" ? TS.TaskStore.error : TS.TaskStore.counts.today + " tareas para hoy"
        color: App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.md
    }
}
