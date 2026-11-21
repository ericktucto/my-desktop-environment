import QtQuick
import "../rows/" as R
import "../../../services/settings/" as ST
import "../../../" as App

// Productividad: el calendario (zona horaria y feriados), las tareas y el temporizador del panel de la isla central.
Page {
    id: page

    readonly property var cal: ST.SettingsStore.calendar
    readonly property var tasks: ST.SettingsStore.tasks
    readonly property var timer: ST.SettingsStore.timer
    readonly property var pomo: ST.SettingsStore.timer.pomodoro

    // Calendarios públicos de feriados de Google (id = el de «<id>#holiday@group.v.calendar.google.com»)
    readonly property var countries: [
        {
            id: "",
            label: "Ninguno"
        },
        {
            id: "es.pe",
            label: "Perú"
        },
        {
            id: "es.ar",
            label: "Argentina"
        },
        {
            id: "es.bo",
            label: "Bolivia"
        },
        {
            id: "es.cl",
            label: "Chile"
        },
        {
            id: "es.co",
            label: "Colombia"
        },
        {
            id: "es.ec",
            label: "Ecuador"
        },
        {
            id: "es.mexican",
            label: "México"
        },
        {
            id: "es.uy",
            label: "Uruguay"
        },
        {
            id: "es.ve",
            label: "Venezuela"
        },
        {
            id: "es.spain",
            label: "España"
        },
        {
            id: "en.usa",
            label: "Estados Unidos"
        },
        {
            id: "en.uk",
            label: "Reino Unido"
        },
        {
            id: "pt.brazilian",
            label: "Brasil"
        },
        {
            id: "fr.french",
            label: "Francia"
        },
        {
            id: "de.german",
            label: "Alemania"
        },
        {
            id: "it.italian",
            label: "Italia"
        }
    ]
    readonly property string suffix: "#holiday@group.v.calendar.google.com"
    // El país elegido: la lista si el id es de ella; si no, «Otro» (id propio)
    readonly property string countryId: {
        const h = cal.holidays;
        if (h === "")
            return "";
        const id = h.endsWith(suffix) ? h.slice(0, -suffix.length) : h;
        return countries.some(c => c.id === id) && h.endsWith(suffix) ? id : "other";
    }

    // «1, 3, 5» → [1, 3, 5] (minutos enteros, sin repetir, hasta 12)
    function parsePresets(text) {
        const out = [];
        for (const t of text.split(/[\s,;]+/)) {
            const n = parseInt(t);
            if (n > 0 && n <= 600 && out.indexOf(n) < 0)
                out.push(n);
        }
        return out.slice(0, 12);
    }

    function hourText(h) {
        return h >= 24 ? "Sin resumen" : String(h).padStart(2, "0") + ":00";
    }

    pageId: "productivity"
    pageName: "Productividad"
    subtitle: "El calendario, las tareas y el temporizador del panel de la isla central."

    R.Section {
        text: "Calendario"
    }
    R.TextRow {
        searchId: "calZone"
        label: "Zona horaria"
        hint: "Para crear eventos en Google, como America/Lima. Vacía, la del sistema."
        keywords: "calendario hora region utc"
        value: page.cal.timeZone
        defaultValue: ""
        placeholder: "del sistema"
        fieldWidth: 180
        onAccepted: t => page.cal.timeZone = t.trim()
    }
    R.CycleRow {
        searchId: "calHolidays"
        label: "Feriados"
        hint: "Se muestran en el calendario. Sin país, solo los de tu cuenta de Google."
        keywords: "calendario pais fiestas festivos"
        options: page.countries.concat(page.countryId === "other" ? [
            {
                id: "other",
                label: "Otro (id propio)"
            }
        ] : [])
        value: page.countryId
        defaultValue: "es.pe"
        changed: page.cal.holidays !== App.Config.calendar.holidays
        onPicked: id => {
            if (id !== "other")
                page.cal.holidays = id === "" ? "" : id + page.suffix;
        }
    }
    R.TextRow {
        searchId: "calHolidaysId"
        label: "Feriados: id de otro calendario"
        hint: "Para un país que no está en la lista: el id del calendario público de Google."
        keywords: "calendario feriados fiestas"
        value: page.countryId === "other" ? page.cal.holidays : ""
        placeholder: "ninguno"
        fieldWidth: 260
        onAccepted: t => {
            if (t.trim() !== "")
                page.cal.holidays = t.trim();
        }
    }
    R.StepperRow {
        searchId: "calRefresh"
        label: "Actualizar el calendario"
        hint: "Cada cuántos minutos. «Al abrir» lo hace al abrir el panel, al iniciar y al despertar."
        keywords: "calendario sincronizar minutos"
        text: page.cal.refresh > 0 ? page.cal.refresh + " min" : "Al abrir"
        changed: page.cal.refresh !== 0
        onResetRequested: page.cal.refresh = 0
        onDecrement: page.cal.refresh = page.cal.refresh <= 5 ? 0 : page.cal.refresh - 5
        onIncrement: page.cal.refresh = Math.min(120, page.cal.refresh === 0 ? 5 : page.cal.refresh + 5)
    }
    R.ChoiceRow {
        searchId: "calView"
        label: "Vista"
        hint: "La que se abre; cambia al elegir otra en el panel."
        keywords: "calendario mes semana dia"
        options: [
            {
                id: "month",
                label: "Mes"
            },
            {
                id: "week",
                label: "Semana"
            },
            {
                id: "days3",
                label: "3 días"
            },
            {
                id: "day",
                label: "Día"
            }
        ]
        value: page.cal.view
        defaultValue: "month"
        onPicked: id => page.cal.view = id
    }

    R.Section {
        text: "Tareas"
    }
    R.StepperRow {
        searchId: "tasksUpcoming"
        label: "Días de «Próximos»"
        keywords: "tareas proximos semana"
        text: page.tasks.upcomingDays + " días"
        changed: page.tasks.upcomingDays !== App.Config.tasks.upcomingDays
        onResetRequested: page.tasks.upcomingDays = App.Config.tasks.upcomingDays
        onDecrement: page.tasks.upcomingDays = Math.max(2, page.tasks.upcomingDays - 1)
        onIncrement: page.tasks.upcomingDays = Math.min(60, page.tasks.upcomingDays + 1)
    }
    R.StepperRow {
        searchId: "tasksSummary"
        label: "Resumen de la mañana"
        hint: "A partir de qué hora avisa cuántas tareas tienes hoy, una vez al día."
        keywords: "tareas aviso hoy hora"
        text: page.hourText(page.tasks.summaryHour)
        changed: page.tasks.summaryHour !== App.Config.tasks.summaryHour
        onResetRequested: page.tasks.summaryHour = App.Config.tasks.summaryHour
        onDecrement: page.tasks.summaryHour = Math.max(0, page.tasks.summaryHour - 1)
        onIncrement: page.tasks.summaryHour = Math.min(24, page.tasks.summaryHour + 1)
    }
    R.StepperRow {
        searchId: "tasksArchive"
        label: "Archivar lo hecho"
        hint: "Lo completado hace más de estos días pasa al archivo."
        keywords: "tareas completadas historial"
        text: page.tasks.archiveDays + " días"
        changed: page.tasks.archiveDays !== App.Config.tasks.archiveDays
        onResetRequested: page.tasks.archiveDays = App.Config.tasks.archiveDays
        onDecrement: page.tasks.archiveDays = Math.max(1, page.tasks.archiveDays - (page.tasks.archiveDays > 30 ? 10 : 1))
        onIncrement: page.tasks.archiveDays = Math.min(365, page.tasks.archiveDays + (page.tasks.archiveDays >= 30 ? 10 : 1))
    }

    R.Section {
        text: "Temporizador"
    }
    R.TextRow {
        searchId: "timerPresets"
        label: "Tiempos rápidos"
        hint: "Minutos separados por comas, hasta 12."
        keywords: "temporizador botones minutos"
        value: page.timer.presets.join(", ")
        defaultValue: App.Config.timer.presets.join(", ")
        fieldWidth: 220
        onAccepted: t => {
            const list = page.parsePresets(t);
            if (list.length > 0)
                page.timer.presets = list;
        }
    }
    R.FileRow {
        searchId: "timerSound"
        label: "Sonido de la alarma"
        hint: "El del tema del sistema o un archivo tuyo (oga, ogg, wav, flac o mp3)."
        keywords: "temporizador alarma audio"
        kind: "file"
        patterns: ["*.oga", "*.ogg", "*.wav", "*.flac", "*.mp3"]
        dialogTitle: "Sonido de la alarma"
        defaultText: "Sonido del sistema"
        value: page.timer.sound === "system" ? "" : page.timer.sound
        onPicked: p => page.timer.sound = p === "" ? "system" : p
    }
    R.StepperRow {
        searchId: "pomoWork"
        label: "Pomodoro: trabajo"
        keywords: "temporizador pomodoro concentracion"
        text: page.pomo.work + " min"
        changed: page.pomo.work !== App.Config.timer.pomodoro.work
        onResetRequested: page.pomo.work = App.Config.timer.pomodoro.work
        onDecrement: page.pomo.work = page.pomo.work > 5 ? page.pomo.work - 5 : 1
        onIncrement: page.pomo.work = Math.min(120, page.pomo.work === 1 ? 5 : page.pomo.work + 5)
    }
    R.StepperRow {
        searchId: "pomoShort"
        label: "Pomodoro: descanso corto"
        keywords: "temporizador pomodoro pausa"
        text: page.pomo.shortBreak + " min"
        changed: page.pomo.shortBreak !== App.Config.timer.pomodoro.short
        onResetRequested: page.pomo.shortBreak = App.Config.timer.pomodoro.short
        onDecrement: page.pomo.shortBreak = Math.max(1, page.pomo.shortBreak - 1)
        onIncrement: page.pomo.shortBreak = Math.min(60, page.pomo.shortBreak + 1)
    }
    R.StepperRow {
        searchId: "pomoLong"
        label: "Pomodoro: descanso largo"
        keywords: "temporizador pomodoro pausa"
        text: page.pomo.longBreak + " min"
        changed: page.pomo.longBreak !== App.Config.timer.pomodoro.long
        onResetRequested: page.pomo.longBreak = App.Config.timer.pomodoro.long
        onDecrement: page.pomo.longBreak = page.pomo.longBreak > 5 ? page.pomo.longBreak - 5 : 1
        onIncrement: page.pomo.longBreak = Math.min(120, page.pomo.longBreak === 1 ? 5 : page.pomo.longBreak + 5)
    }
    R.StepperRow {
        searchId: "pomoEvery"
        label: "Pomodoro: descanso largo cada"
        hint: "Cuántos tramos de trabajo hay antes del descanso largo."
        keywords: "temporizador pomodoro ciclos"
        text: page.pomo.every + " tramos"
        changed: page.pomo.every !== App.Config.timer.pomodoro.every
        onResetRequested: page.pomo.every = App.Config.timer.pomodoro.every
        onDecrement: page.pomo.every = Math.max(2, page.pomo.every - 1)
        onIncrement: page.pomo.every = Math.min(12, page.pomo.every + 1)
    }

    R.ActionRow {
        searchId: "resetProductivity"
        label: "Restablecer la productividad"
        keywords: "restaurar defecto"
        actionLabel: "Restablecer"
        onTriggered: {
            ST.SettingsStore.resetSection("calendar");
            ST.SettingsStore.resetSection("tasks");
            ST.SettingsStore.resetSection("timer");
        }
    }
}
