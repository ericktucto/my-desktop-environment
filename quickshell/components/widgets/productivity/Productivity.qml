import QtQuick
import "../../../" as App

// Modo "productivity" de la isla central. Por ahora una sola pestaña (Calendario), así que no se
// dibuja la barra de pestañas; Tareas y Temporizador se suman después.
Item {
    id: root

    signal closeRequested

    implicitHeight: calendar.implicitHeight

    // Esc: true si cerró algo dentro del panel (menú, selector, evento desplegado)
    function back() {
        return calendar.back();
    }

    onVisibleChanged: {
        if (visible)
            calendar.forceActiveFocus();
        else
            calendar.reset();
    }

    CalendarPanel {
        id: calendar
        width: parent.width
        onCloseRequested: root.closeRequested()
    }
}
