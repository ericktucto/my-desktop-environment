import QtQuick
import Quickshell
import "../../" as App
import "../../services/calendar/" as CS
import "../../services/settings/" as ST
import "../../services/settings/Clock.js" as Fmt

Text {
    // Con `showDate`: "lun 16 nov" y, si hay uno cerca, el próximo evento
    property bool showDate: false
    // Preferencias → Bloqueo y reloj
    text: showDate ? CS.CalendarStore.hoverText : Fmt.time(clock.date, ST.SettingsStore.clock.hour12, ST.SettingsStore.clock.seconds)
    color: App.Theme.white
    font.family: App.Config.fonts.mono
    font.pixelSize: App.Config.fontSize.md
    font.weight: Font.Medium
    anchors.verticalCenter: parent.verticalCenter

    // El SystemClock vive AQUÍ, dentro del componente Clock
    SystemClock {
        id: clock
        precision: ST.SettingsStore.clock.seconds ? SystemClock.Seconds : SystemClock.Minutes
    }
}
