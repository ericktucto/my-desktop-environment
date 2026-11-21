import QtQuick
import "../rows/" as R
import "../../../services/notify/" as N
import "../../../services/settings/" as ST
import "../../../services/sound/" as SND
import "../../../" as App

// Notificaciones: cuánto dura un popup, cuántos a la vez, No molestar programado y apps silenciadas.
Page {
    id: page

    readonly property var cfg: ST.SettingsStore.notifications
    readonly property var dnd: ST.SettingsStore.notifications.dndSchedule

    function validTime(t) {
        return N.NotificationStore.minutesOf(t.trim()) >= 0;
    }
    // «7:5» → «07:05»
    function normTime(t) {
        const m = N.NotificationStore.minutesOf(t.trim());
        return String(Math.floor(m / 60)).padStart(2, "0") + ":" + String(m % 60).padStart(2, "0");
    }

    pageId: "notifications"
    pageName: "Notificaciones"
    subtitle: "Los avisos que salen en pantalla. Lo que no sale sigue en el historial de la pill de notificaciones."

    R.Section {
        text: "Popups"
    }
    R.StepperRow {
        searchId: "notifTimeout"
        label: "Duración del popup"
        hint: "Si la app no indica cuánto debe durar. Las urgentes no se cierran solas."
        keywords: "tiempo segundos aviso"
        text: page.cfg.timeout + " s"
        changed: page.cfg.timeout !== App.Config.notifications.popupTimeout / 1000
        onResetRequested: page.cfg.timeout = App.Config.notifications.popupTimeout / 1000
        onDecrement: page.cfg.timeout = Math.max(1, page.cfg.timeout - 1)
        onIncrement: page.cfg.timeout = Math.min(30, page.cfg.timeout + 1)
    }
    R.StepperRow {
        searchId: "notifMaxPopups"
        label: "Popups a la vez"
        hint: "Los demás solo van al historial."
        keywords: "cantidad maximo"
        text: String(page.cfg.maxPopups)
        changed: page.cfg.maxPopups !== App.Config.notifications.maxPopups
        onResetRequested: page.cfg.maxPopups = App.Config.notifications.maxPopups
        onDecrement: page.cfg.maxPopups = Math.max(1, page.cfg.maxPopups - 1)
        onIncrement: page.cfg.maxPopups = Math.min(6, page.cfg.maxPopups + 1)
    }

    R.Section {
        text: "No molestar programado"
    }
    R.SwitchRow {
        searchId: "dndSchedule"
        label: "Activar No molestar con horario"
        hint: "Se activa a la hora de inicio y se apaga a la de fin. Las urgentes siguen saliendo."
        keywords: "dnd noche silencio programar"
        checked: page.dnd.enabled
        defaultValue: false
        onToggled: c => page.dnd.enabled = c
    }
    R.TextRow {
        searchId: "dndFrom"
        label: "Desde"
        hint: "Hora de inicio, como 22:00."
        keywords: "dnd horario inicio"
        value: page.dnd.from
        defaultValue: "22:00"
        fieldWidth: 80
        placeholder: "22:00"
        onAccepted: t => page.dnd.from = page.validTime(t) ? page.normTime(t) : page.dnd.from
    }
    R.TextRow {
        searchId: "dndTo"
        label: "Hasta"
        hint: "Hora de fin, como 07:00. Si es menor que la de inicio, termina al día siguiente."
        keywords: "dnd horario fin"
        value: page.dnd.to
        defaultValue: "07:00"
        fieldWidth: 80
        placeholder: "07:00"
        onAccepted: t => page.dnd.to = page.validTime(t) ? page.normTime(t) : page.dnd.to
    }

    R.Section {
        text: "Apps"
    }
    Text {
        width: page.width - 16
        wrapMode: Text.WordWrap
        text: N.NotificationStore.appNames.length === 0 ? "Aún no ha notificado ninguna app. Cuando lo hagan aparecerán aquí." : "Silenciar: llega al historial ya leída, sin popup ni sonido. Sonido: uno propio para las notificaciones de esa app."
        color: App.Theme.gray
        font.family: App.Config.fonts.text
        font.pixelSize: App.Config.fontSize.sm
    }
    // Las que tienen un ajuste propio (silenciadas o con sonido) van arriba; el resto, plegado
    property bool showAll: false
    readonly property var tuned: N.NotificationStore.appNames.filter(a => N.NotificationStore.isMuted(a) || SND.SoundStore.appSound(a) !== "")
    readonly property var others: N.NotificationStore.appNames.filter(a => !tuned.includes(a))

    Repeater {
        model: page.tuned
        R.NotifyAppRow {
            required property string modelData
            app: modelData
        }
    }
    R.ActionRow {
        visible: page.others.length > 0
        searchId: "notifMoreApps"
        label: "Más apps (" + page.others.length + ")"
        hint: "Las que han notificado y no tienen ajustes propios."
        keywords: "apps silenciar sonido notificaciones"
        actionLabel: page.showAll ? "Ocultar" : "Mostrar"
        onTriggered: page.showAll = !page.showAll
    }
    Repeater {
        model: page.showAll ? page.others : []
        R.NotifyAppRow {
            required property string modelData
            app: modelData
        }
    }

    R.ActionRow {
        searchId: "resetNotifications"
        label: "Restablecer las notificaciones"
        keywords: "restaurar defecto"
        actionLabel: "Restablecer"
        onTriggered: ST.SettingsStore.resetSection("notifications")
    }
}
