import QtQuick
import Quickshell
import "../../" as App
import "../../services/calendar/" as CS

Text {
    // Con `showDate`: "lun 16 nov" y, si hay uno cerca, el próximo evento
    property bool showDate: false

    text: showDate ? CS.CalendarStore.hoverText : Qt.formatDateTime(clock.date, "hh:mm AP")
    color: App.Theme.white
    font.family: App.Config.fonts.mono
    font.pixelSize: App.Config.fontSize.md
    font.weight: Font.Medium
    anchors.verticalCenter: parent.verticalCenter

    // El SystemClock vive AQUÍ, dentro del componente Clock
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
