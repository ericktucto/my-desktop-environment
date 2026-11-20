import QtQuick
import Quickshell
import "../../" as App
import "../../services/calendar/" as CS
import "../../services/settings/" as ST

Text {
    // Con `showDate`: "lun 16 nov" y, si hay uno cerca, el próximo evento
    property bool showDate: false
    // Preferencias → Barra e isla → Reloj
    readonly property string format: (ST.SettingsStore.clock.hour12 ? "hh:mm" : "HH:mm") + (ST.SettingsStore.clock.seconds ? ":ss" : "") + (ST.SettingsStore.clock.hour12 ? " AP" : "")

    text: showDate ? CS.CalendarStore.hoverText : Qt.formatDateTime(clock.date, format)
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
