import QtQuick
import "../rows/" as R
import "../../../services/settings/" as ST
import "../../../services/settings/Clock.js" as Fmt
import "../../../" as App

// Bloqueo y reloj: el fondo y lo que muestra la pantalla de bloqueo, y la hora y la fecha de toda la shell
// (la barra, la fecha al pasar el mouse, el calendario y el bloqueo).
Page {
    id: page

    readonly property var lockCfg: ST.SettingsStore.lock
    readonly property var clockCfg: ST.SettingsStore.clock
    // Hora de ejemplo para ver cómo queda el formato
    readonly property date sample: new Date(2026, 10, 16, 17, 7, 9)

    pageId: "lock"
    pageName: "Bloqueo y reloj"
    subtitle: "Cómo se ve la pantalla de bloqueo y cómo se escriben la hora y la fecha en toda la shell."

    R.Section {
        text: "Pantalla de bloqueo"
    }
    R.SliderRow {
        searchId: "lockBlur"
        label: "Desenfoque del fondo"
        keywords: "bloqueo wallpaper blur"
        defaultValue: App.Config.lock.blur
        value: page.lockCfg.blur
        onMoved: v => page.lockCfg.blur = v
    }
    R.SliderRow {
        searchId: "lockDim"
        label: "Oscurecido del fondo"
        keywords: "bloqueo wallpaper oscuro brillo"
        defaultValue: App.Config.lock.dim
        value: page.lockCfg.dim
        onMoved: v => page.lockCfg.dim = v
    }
    R.SwitchRow {
        searchId: "lockNotifications"
        label: "Notificaciones en el bloqueo"
        hint: "Las no leídas de las últimas 24 h, en la pantalla de la laptop."
        keywords: "bloqueo avisos"
        checked: page.lockCfg.notifications
        defaultValue: true
        onToggled: c => page.lockCfg.notifications = c
    }
    R.SwitchRow {
        searchId: "lockMedia"
        label: "Música en el bloqueo"
        hint: "Carátula, título y controles de lo que suena."
        keywords: "bloqueo reproductor media spotify"
        checked: page.lockCfg.media
        defaultValue: true
        onToggled: c => page.lockCfg.media = c
    }

    R.Section {
        text: "Hora y fecha"
    }
    R.SwitchRow {
        searchId: "clock12"
        label: "Formato de 12 horas"
        hint: "Con AM/PM. Apagado, 24 horas."
        keywords: "hora reloj am pm 24"
        checked: page.clockCfg.hour12
        defaultValue: true
        onToggled: c => page.clockCfg.hour12 = c
    }
    R.SwitchRow {
        searchId: "clockSeconds"
        label: "Mostrar segundos"
        keywords: "hora reloj"
        checked: page.clockCfg.seconds
        defaultValue: false
        onToggled: c => page.clockCfg.seconds = c
    }
    R.ChoiceRow {
        searchId: "dateFormat"
        label: "Formato de la fecha"
        keywords: "fecha dia mes año orden"
        options: [
            {
                id: "text",
                label: "lun 16 nov"
            },
            {
                id: "dmy",
                label: "16/11/2026"
            },
            {
                id: "mdy",
                label: "11/16/2026"
            },
            {
                id: "iso",
                label: "2026-11-16"
            }
        ]
        value: page.clockCfg.dateFormat
        defaultValue: "text"
        onPicked: id => page.clockCfg.dateFormat = id
    }
    R.InfoRow {
        label: "Así se ve"
        hint: "En la barra y en el bloqueo."
        value: Fmt.time(page.sample, page.clockCfg.hour12, page.clockCfg.seconds) + "  ·  " + Fmt.date(page.sample, page.clockCfg.dateFormat, false)
        valueColor: App.Theme.white
    }

    R.ActionRow {
        searchId: "resetLock"
        label: "Restablecer el bloqueo y el reloj"
        keywords: "restaurar defecto"
        actionLabel: "Restablecer"
        onTriggered: {
            ST.SettingsStore.resetSection("lock");
            ST.SettingsStore.resetSection("clock");
        }
    }
}
